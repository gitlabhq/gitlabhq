module API
  class Notes < Grape::API
    include PaginationParams
    helpers ::API::Helpers::NotesHelpers

    before { authenticate! }

    NOTEABLE_TYPES = [Issue, MergeRequest, Snippet, Epic].freeze

    NOTEABLE_TYPES.each do |noteable_type|
      parent_type = noteable_type.parent_class.to_s.underscore
      noteables_str = noteable_type.to_s.underscore.pluralize

      params do
        requires :id, type: String, desc: "The ID of a #{parent_type}"
      end
      resource parent_type.pluralize.to_sym, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
        noteables_str = noteable_type.to_s.underscore.pluralize

        desc "Get a list of #{noteable_type.to_s.downcase} notes" do
          success Entities::Note
        end
        params do
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
          optional :order_by, type: String, values: %w[created_at updated_at], default: 'created_at',
                              desc: 'Return notes ordered by `created_at` or `updated_at` fields.'
          optional :sort, type: String, values: %w[asc desc], default: 'desc',
                          desc: 'Return notes sorted in `asc` or `desc` order.'
          use :pagination
        end
        get ":id/#{noteables_str}/:noteable_id/notes" do
          noteable = find_noteable(parent_type, noteables_str, params[:noteable_id])

          if can?(current_user, noteable_read_ability_name(noteable), noteable)
            # We exclude notes that are cross-references and that cannot be viewed
            # by the current user. By doing this exclusion at this level and not
            # at the DB query level (which we cannot in that case), the current
            # page can have less elements than :per_page even if
            # there's more than one page.
            raw_notes = noteable.notes.with_metadata.reorder(params[:order_by] => params[:sort])
            notes =
              # paginate() only works with a relation. This could lead to a
              # mismatch between the pagination headers info and the actual notes
              # array returned, but this is really a edge-case.
              paginate(raw_notes)
              .reject { |n| n.cross_reference_not_visible_for?(current_user) }
            present notes, with: Entities::Note
          else
            not_found!("Notes")
          end
        end

        desc "Get a single #{noteable_type.to_s.downcase} note" do
          success Entities::Note
        end
        params do
          requires :note_id, type: Integer, desc: 'The ID of a note'
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
        end
        get ":id/#{noteables_str}/:noteable_id/notes/:note_id" do
          noteable = find_noteable(parent_type, noteables_str, params[:noteable_id])
          get_note(noteable, params[:note_id])
        end

        desc "Create a new #{noteable_type.to_s.downcase} note" do
          success Entities::Note
        end
        params do
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
          requires :body, type: String, desc: 'The content of a note'
          optional :created_at, type: String, desc: 'The creation date of the note'
        end
        post ":id/#{noteables_str}/:noteable_id/notes" do
          noteable = find_noteable(parent_type, noteables_str, params[:noteable_id])

          opts = {
            note: params[:body],
            noteable_type: noteables_str.classify,
            noteable_id: noteable.id,
            created_at: params[:created_at]
          }

          note = create_note(noteable, opts)

          if note.valid?
            present note, with: Entities.const_get(note.class.name)
          else
            bad_request!("Note #{note.errors.messages}")
          end
        end

        desc "Update an existing #{noteable_type.to_s.downcase} note" do
          success Entities::Note
        end
        params do
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
          requires :note_id, type: Integer, desc: 'The ID of a note'
          requires :body, type: String, desc: 'The content of a note'
        end
        put ":id/#{noteables_str}/:noteable_id/notes/:note_id" do
          noteable = find_noteable(parent_type, noteables_str, params[:noteable_id])

          update_note(noteable, params[:note_id])
        end

        desc "Delete a #{noteable_type.to_s.downcase} note" do
          success Entities::Note
        end
        params do
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
          requires :note_id, type: Integer, desc: 'The ID of a note'
        end
        delete ":id/#{noteables_str}/:noteable_id/notes/:note_id" do
          noteable = find_noteable(parent_type, noteables_str, params[:noteable_id])

          delete_note(noteable, params[:note_id])
        end
      end
    end
  end
end
