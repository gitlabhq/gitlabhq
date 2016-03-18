module API
  # Notes API
  class Notes < Grape::API
    before { authenticate! }

    NOTEABLE_TYPES = [Issue, MergeRequest, Snippet]

    resource :projects do
      NOTEABLE_TYPES.each do |noteable_type|
        noteables_str = noteable_type.to_s.underscore.pluralize
        noteable_id_str = "#{noteable_type.to_s.underscore}_id"

        # Get a list of project +noteable+ notes
        #
        # Parameters:
        #   id (required) - The ID of a project
        #   noteable_id (required) - The ID of an issue or snippet
        # Example Request:
        #   GET /projects/:id/issues/:noteable_id/notes
        #   GET /projects/:id/snippets/:noteable_id/notes
        get ":id/#{noteables_str}/:#{noteable_id_str}/notes" do
          @noteable = user_project.send(:"#{noteables_str}").find(params[:"#{noteable_id_str}"])

          # We exclude notes that are cross-references and that cannot be viewed
          # by the current user. By doing this exclusion at this level and not
          # at the DB query level (which we cannot in that case), the current
          # page can have less elements than :per_page even if
          # there's more than one page.
          notes =
            # paginate() only works with a relation. This could lead to a
            # mismatch between the pagination headers info and the actual notes
            # array returned, but this is really a edge-case.
            paginate(@noteable.notes).
            reject { |n| n.cross_reference_not_visible_for?(current_user) }
          present notes, with: Entities::Note
        end

        # Get a single +noteable+ note
        #
        # Parameters:
        #   id (required) - The ID of a project
        #   noteable_id (required) - The ID of an issue or snippet
        #   note_id (required) - The ID of a note
        # Example Request:
        #   GET /projects/:id/issues/:noteable_id/notes/:note_id
        #   GET /projects/:id/snippets/:noteable_id/notes/:note_id
        get ":id/#{noteables_str}/:#{noteable_id_str}/notes/:note_id" do
          @noteable = user_project.send(:"#{noteables_str}").find(params[:"#{noteable_id_str}"])
          @note = @noteable.notes.find(params[:note_id])

          if @note.cross_reference_not_visible_for?(current_user)
            not_found!("Note")
          else
            present @note, with: Entities::Note
          end
        end

        # Create a new +noteable+ note
        #
        # Parameters:
        #   id (required) - The ID of a project
        #   noteable_id (required) - The ID of an issue or snippet
        #   body (required) - The content of a note
        # Example Request:
        #   POST /projects/:id/issues/:noteable_id/notes
        #   POST /projects/:id/snippets/:noteable_id/notes
        post ":id/#{noteables_str}/:#{noteable_id_str}/notes" do
          required_attributes! [:body]

          opts = {
           note: params[:body],
           noteable_type: noteables_str.classify,
           noteable_id: params[noteable_id_str]
          }

          @note = ::Notes::CreateService.new(user_project, current_user, opts).execute

          if @note.valid?
            present @note, with: Entities::Note
          else
            not_found!("Note #{@note.errors.messages}")
          end
        end

        # Modify existing +noteable+ note
        #
        # Parameters:
        #   id (required) - The ID of a project
        #   noteable_id (required) - The ID of an issue or snippet
        #   node_id (required) - The ID of a note
        #   body (required) - New content of a note
        # Example Request:
        #   PUT /projects/:id/issues/:noteable_id/notes/:note_id
        #   PUT /projects/:id/snippets/:noteable_id/notes/:node_id
        put ":id/#{noteables_str}/:#{noteable_id_str}/notes/:note_id" do
          required_attributes! [:body]

          note = user_project.notes.find(params[:note_id])

          authorize! :admin_note, note

          opts = {
            note: params[:body]
          }

          @note = ::Notes::UpdateService.new(user_project, current_user, opts).execute(note)

          if @note.valid?
            present @note, with: Entities::Note
          else
            render_api_error!("Failed to save note #{note.errors.messages}", 400)
          end
        end

      end
    end
  end
end
