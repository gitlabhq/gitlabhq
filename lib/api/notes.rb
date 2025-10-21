# frozen_string_literal: true

module API
  class Notes < ::API::Base
    include PaginationParams
    include APIGuard

    helpers ::API::Helpers::NotesHelpers

    before { authenticate! }

    allow_access_with_scope :ai_workflows, if: ->(request) do
      request.get? || request.head? || request.post?
    end

    urgency :low, [
      '/projects/:id/merge_requests/:noteable_id/notes',
      '/projects/:id/merge_requests/:noteable_id/notes/:note_id',
      '/projects/:id/issues/:noteable_id/notes',
      '/projects/:id/issues/:noteable_id/notes/:note_id',
      '/groups/:id/epics/:noteable_id/notes',
      '/groups/:id/epics/:noteable_id/notes/:note_id'
    ]

    Helpers::NotesHelpers.noteable_types.each do |noteable_type|
      parent_type = noteable_type.parent_type
      noteables_str = noteable_type.noteables_str
      feature_category = noteable_type.feature_category
      noteable_class = noteable_type.noteable_class

      params do
        requires :id, type: String, desc: "The ID of a #{parent_type}"
      end
      resource parent_type.pluralize.to_sym, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc "Get a list of #{noteable_type.human_name} notes" do
          success Entities::Note
        end
        params do
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
          optional :order_by, type: String, values: %w[created_at updated_at], default: 'created_at',
            desc: 'Return notes ordered by `created_at` or `updated_at` fields.'
          optional :sort, type: String, values: %w[asc desc], default: 'desc',
            desc: 'Return notes sorted in `asc` or `desc` order.'
          optional :activity_filter, type: String, values: UserPreference::NOTES_FILTERS.stringify_keys.keys, default: 'all_notes',
            desc: 'The type of notables which are returned.'
          use :pagination
        end

        policy = Helpers::NotesHelpers.job_token_policy_for(noteable_type, 'GET')

        if policy
          route_setting :authentication, job_token_allowed: true
          route_setting :authorization, job_token_policies: policy,
            allow_public_access_for_enabled_project_features: [:repository, :merge_requests]
        end

        # rubocop: disable CodeReuse/ActiveRecord
        get ":id/#{noteables_str}/:noteable_id/notes", feature_category: feature_category do
          noteable = find_noteable(noteable_class, params[:noteable_id], parent_type)

          # We exclude notes that are cross-references and that cannot be viewed
          # by the current user. By doing this exclusion at this level and not
          # at the DB query level (which we cannot in that case), the current
          # page can have less elements than :per_page even if
          # there's more than one page.
          notes_filter = UserPreference::NOTES_FILTERS[params[:activity_filter].to_sym]
          raw_notes = noteable.notes.with_metadata.with_notes_filter(notes_filter).reorder(order_options_with_tie_breaker)

          # paginate() only works with a relation. This could lead to a
          # mismatch between the pagination headers info and the actual notes
          # array returned, but this is really a edge-case.
          notes = paginate(raw_notes)
          notes = prepare_notes_for_rendering(notes)
          notes = notes.select { |note| note.readable_by?(current_user) }
          present notes, with: Entities::Note, current_user: current_user
        end
        # rubocop: enable CodeReuse/ActiveRecord

        desc "Get a single #{noteable_type.human_name} note" do
          success Entities::Note
        end
        params do
          requires :note_id, type: Integer, desc: 'The ID of a note'
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
        end
        policy = Helpers::NotesHelpers.job_token_policy_for(noteable_type, 'GET')

        if policy
          route_setting :authentication, job_token_allowed: true
          route_setting :authorization, job_token_policies: policy,
            allow_public_access_for_enabled_project_features: [:repository, :merge_requests]
        end

        get ":id/#{noteables_str}/:noteable_id/notes/:note_id", feature_category: feature_category do
          noteable = find_noteable(noteable_class, params[:noteable_id], parent_type)
          get_note(noteable, params[:note_id])
        end

        desc "Create a new #{noteable_type.human_name} note" do
          success Entities::Note
        end
        params do
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
          requires :body, type: String, desc: 'The content of a note'
          optional :confidential, type: Boolean, desc: '[Deprecated in 15.5] Renamed to internal'
          optional :internal, type: Boolean, desc: 'Internal note flag, default is false'
          optional :created_at, type: String, desc: 'The creation date of the note'
          optional :merge_request_diff_head_sha, type: String, desc: 'The SHA of the head commit'
        end
        post ":id/#{noteables_str}/:noteable_id/notes", feature_category: feature_category do
          allowlist =
            Gitlab::CurrentSettings.current_application_settings.notes_create_limit_allowlist
          check_rate_limit! :notes_create, scope: current_user, users_allowlist: allowlist
          noteable = find_noteable(noteable_class, params[:noteable_id], parent_type)
          validator = ::Gitlab::Auth::ScopeValidator.new(current_user, Gitlab::Auth::RequestAuthenticator.new(request))
          opts = {
            note: params[:body],
            noteable_type: noteable.class.name,
            noteable_id: noteable.id,
            internal: params[:internal] || params[:confidential],
            created_at: params[:created_at],
            merge_request_diff_head_sha: params[:merge_request_diff_head_sha],
            scope_validator: validator
          }

          begin
            note = create_note(noteable, opts)

            process_note_creation_result(note) do
              present note, with: Entities.const_get(note.class.name, false)
            end
          rescue QuickActions::InterpretService::QuickActionsNotAllowedError => error
            forbidden!(error.message)
          end
        end

        desc "Update an existing #{noteable_type.human_name} note" do
          success Entities::Note
        end
        params do
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
          requires :note_id, type: Integer, desc: 'The ID of a note'
          optional :body, type: String, allow_blank: false, desc: 'The content of a note'
          optional :confidential, type: Boolean, desc: '[Deprecated in 14.10] No longer allowed to update confidentiality of notes'
        end
        put ":id/#{noteables_str}/:noteable_id/notes/:note_id", feature_category: feature_category do
          noteable = find_noteable(noteable_class, params[:noteable_id], parent_type)

          update_note(noteable, params[:note_id])
        end

        desc "Delete a #{noteable_type.human_name} note" do
          success Entities::Note
        end
        params do
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
          requires :note_id, type: Integer, desc: 'The ID of a note'
        end
        delete ":id/#{noteables_str}/:noteable_id/notes/:note_id" do
          noteable = find_noteable(noteable_class, params[:noteable_id], parent_type)

          delete_note(noteable, params[:note_id])
        end
      end
    end
  end
end
