# frozen_string_literal: true

module API
  class Discussions < ::API::Base
    include PaginationParams
    helpers ::API::Helpers::NotesHelpers
    helpers ::RendersNotes

    before { authenticate! }

    urgency :low, [
      '/projects/:id/merge_requests/:noteable_id/discussions',
      '/projects/:id/merge_requests/:noteable_id/discussions/:discussion_id',
      '/projects/:id/merge_requests/:noteable_id/discussions/:discussion_id/notes',
      '/projects/:id/merge_requests/:noteable_id/discussions/:discussion_id/notes/:note_id'
    ]

    Helpers::DiscussionsHelpers.feature_category_per_noteable_type.each do |noteable_type, feature_category|
      parent_type = noteable_type.parent_class.to_s.underscore
      noteables_str = noteable_type.to_s.underscore.pluralize
      notable_name = noteable_type.to_s.underscore.humanize.downcase
      notable_id_type = noteable_type == Commit ? String : Integer
      noteables_path = noteable_type == Commit ? "repository/#{noteables_str}" : noteables_str

      params do
        requires :id, type: String, desc: "The ID of a #{parent_type}"
      end
      resource parent_type.pluralize.to_sym, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc "Get a list of #{notable_name} discussions" do
          success Entities::Discussion
        end
        params do
          requires :noteable_id, type: notable_id_type, desc: "The ID of the #{notable_name}"
          use :pagination
        end

        get ":id/#{noteables_path}/:noteable_id/discussions", feature_category: feature_category do
          noteable = find_noteable(noteable_type, params[:noteable_id])

          discussion_ids = paginate(noteable.discussion_ids_relation)
          notes = readable_discussion_notes(noteable, discussion_ids)

          present Discussion.build_collection(notes, noteable), with: Entities::Discussion
        end

        desc "Get a single #{notable_name} discussion" do
          success Entities::Discussion
        end
        params do
          requires :discussion_id, type: String, desc: 'The ID of a discussion'
          requires :noteable_id, type: notable_id_type, desc: "The ID of the #{notable_name}"
        end
        get ":id/#{noteables_path}/:noteable_id/discussions/:discussion_id", feature_category: feature_category do
          noteable = find_noteable(noteable_type, params[:noteable_id])
          notes = readable_discussion_notes(noteable, params[:discussion_id])

          if notes.empty?
            break not_found!("Discussion")
          end

          discussion = Discussion.build(notes, noteable)

          present discussion, with: Entities::Discussion
        end

        desc "Create a new #{notable_name} discussion" do
          success Entities::Discussion
        end
        params do
          requires :noteable_id, type: notable_id_type, desc: "The ID of the #{notable_name}"
          requires :body, type: String, desc: 'The content of a note'
          optional :created_at, type: String, desc: 'The creation date of the note'

          if [Commit, MergeRequest].include?(noteable_type)
            optional :position, type: Hash do
              requires :base_sha, type: String, desc: 'Base commit SHA in the source branch'
              requires :start_sha, type: String, desc: 'SHA referencing commit in target branch'
              requires :head_sha, type: String, desc: 'SHA referencing HEAD of this merge request'
              requires :position_type, type: String, desc: 'Type of the position reference', values: %w[text image file]
              optional :new_path, type: String, desc: 'File path after change'
              optional :new_line, type: Integer, desc: 'Line number after change'
              optional :old_path, type: String, desc: 'File path before change'
              optional :old_line, type: Integer, desc: 'Line number before change'
              optional :width, type: Integer, desc: 'Width of the image'
              optional :height, type: Integer, desc: 'Height of the image'
              optional :x, type: Integer, desc: 'X coordinate in the image'
              optional :y, type: Integer, desc: 'Y coordinate in the image'

              if noteable_type == MergeRequest
                optional :line_range, type: Hash, desc: 'Multi-line start and end' do
                  optional :start, type: Hash do
                    optional :line_code, type: String, desc: 'Start line code for multi-line note'
                    optional :type, type: String, desc: 'Start line type for multi-line note'
                    optional :old_line, type: String, desc: 'Start old_line line number'
                    optional :new_line, type: String, desc: 'Start new_line line number'
                  end
                  optional :end, type: Hash do
                    optional :line_code, type: String, desc: 'End line code for multi-line note'
                    optional :type, type: String, desc: 'End line type for multi-line note'
                    optional :old_line, type: String, desc: 'End old_line line number'
                    optional :new_line, type: String, desc: 'End new_line line number'
                  end
                end
              end
            end
          end
        end
        post ":id/#{noteables_path}/:noteable_id/discussions", feature_category: feature_category do
          noteable = find_noteable(noteable_type, params[:noteable_id])
          type = params[:position] ? 'DiffNote' : 'DiscussionNote'
          id_key = noteable.is_a?(Commit) ? :commit_id : :noteable_id

          opts = {
            note: params[:body],
            created_at: params[:created_at],
            type: type,
            noteable_type: noteables_str.classify,
            position: params[:position],
            id_key => noteable.id
          }
          opts[:commit_id] = params[:commit_id] if noteable.is_a?(MergeRequest) && type == 'DiffNote'

          note = create_note(noteable, opts)

          process_note_creation_result(note) do
            present note.discussion, with: Entities::Discussion
          end
        end
        desc "Get comments in a single #{notable_name} discussion" do
          success Entities::Discussion
        end
        params do
          requires :discussion_id, type: String, desc: 'The ID of a discussion'
          requires :noteable_id, type: notable_id_type, desc: "The ID of the #{notable_name}"
        end
        get ":id/#{noteables_path}/:noteable_id/discussions/:discussion_id/notes", feature_category: feature_category do
          noteable = find_noteable(noteable_type, params[:noteable_id])
          notes = readable_discussion_notes(noteable, params[:discussion_id])

          if notes.empty?
            break not_found!("Notes")
          end

          present notes, with: Entities::Note
        end

        desc "Add a comment to a #{notable_name} discussion" do
          success Entities::Note
        end
        params do
          requires :noteable_id, type: notable_id_type, desc: "The ID of the #{notable_name}"
          requires :discussion_id, type: String, desc: 'The ID of a discussion'
          requires :body, type: String, desc: 'The content of a note'
          optional :created_at, type: String, desc: 'The creation date of the note'
        end
        post ":id/#{noteables_path}/:noteable_id/discussions/:discussion_id/notes", feature_category: feature_category do
          noteable = find_noteable(noteable_type, params[:noteable_id])
          notes = readable_discussion_notes(noteable, params[:discussion_id])
          first_note = notes.first

          break not_found!("Discussion") if notes.empty?

          unless first_note.part_of_discussion? || first_note.to_discussion.can_convert_to_discussion?
            break bad_request!("Discussion can not be replied to.")
          end

          opts = {
            note: params[:body],
            type: 'DiscussionNote',
            in_reply_to_discussion_id: params[:discussion_id],
            created_at: params[:created_at]
          }
          note = create_note(noteable, opts)

          process_note_creation_result(note) do
            present note, with: Entities::Note
          end
        end

        desc "Get a comment in a #{notable_name} discussion" do
          success Entities::Note
        end
        params do
          requires :noteable_id, type: notable_id_type, desc: "The ID of the #{notable_name}"
          requires :discussion_id, type: String, desc: 'The ID of a discussion'
          requires :note_id, type: Integer, desc: 'The ID of a note'
        end
        get ":id/#{noteables_path}/:noteable_id/discussions/:discussion_id/notes/:note_id", feature_category: feature_category do
          noteable = find_noteable(noteable_type, params[:noteable_id])

          get_note(noteable, params[:note_id])
        end

        desc "Edit a comment in a #{notable_name} discussion" do
          success Entities::Note
        end
        params do
          requires :noteable_id, type: notable_id_type, desc: "The ID of the #{notable_name}"
          requires :discussion_id, type: String, desc: 'The ID of a discussion'
          requires :note_id, type: Integer, desc: 'The ID of a note'
          optional :body, type: String, desc: 'The content of a note'
          optional :resolved, type: Boolean, desc: 'Mark note resolved/unresolved'
          exactly_one_of :body, :resolved
        end
        put ":id/#{noteables_path}/:noteable_id/discussions/:discussion_id/notes/:note_id", feature_category: feature_category do
          noteable = find_noteable(noteable_type, params[:noteable_id])

          if params[:resolved].nil?
            update_note(noteable, params[:note_id])
          else
            resolve_note(noteable, params[:note_id], params[:resolved])
          end
        end

        desc "Delete a comment in a #{notable_name} discussion" do
          success Entities::Note
        end
        params do
          requires :noteable_id, type: notable_id_type, desc: "The ID of the #{notable_name}"
          requires :discussion_id, type: String, desc: 'The ID of a discussion'
          requires :note_id, type: Integer, desc: 'The ID of a note'
        end
        delete ":id/#{noteables_path}/:noteable_id/discussions/:discussion_id/notes/:note_id", feature_category: feature_category do
          noteable = find_noteable(noteable_type, params[:noteable_id])

          delete_note(noteable, params[:note_id])
        end

        if Noteable.resolvable_types.include?(noteable_type.to_s)
          desc "Resolve/unresolve an existing #{notable_name} discussion" do
            success Entities::Discussion
          end
          params do
            requires :noteable_id, type: notable_id_type, desc: "The ID of the #{notable_name}"
            requires :discussion_id, type: String, desc: 'The ID of a discussion'
            requires :resolved, type: Boolean, desc: 'Mark discussion resolved/unresolved'
          end
          put ":id/#{noteables_path}/:noteable_id/discussions/:discussion_id", feature_category: feature_category do
            noteable = find_noteable(noteable_type, params[:noteable_id])

            resolve_discussion(noteable, params[:discussion_id], params[:resolved])
          end
        end
      end
    end

    helpers do
      # rubocop: disable CodeReuse/ActiveRecord
      def readable_discussion_notes(noteable, discussion_ids)
        notes = noteable.notes
          .with_discussion_ids(discussion_ids)
          .inc_relations_for_view(noteable)
          .includes(:noteable)
          .fresh

        # Without RendersActions#prepare_notes_for_rendering,
        # Note#system_note_visible_for? will attempt to render
        # Markdown references mentioned in the note to see whether they
        # should be redacted. For notes that reference a commit, this
        # would also incur a Gitaly call to verify the commit exists.
        #
        # With prepare_notes_for_rendering, we can avoid Gitaly calls
        # because notes are redacted if they point to projects that
        # cannot be accessed by the user.
        notes = prepare_notes_for_rendering(notes)
        notes.select { |n| n.readable_by?(current_user) }
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
