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
          present paginate(@noteable.notes), with: Entities::Note
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
          present @note, with: Entities::Note
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
            not_found!
          end
        end
      end
    end
  end
end
