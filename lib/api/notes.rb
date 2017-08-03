module API
  class Notes < Grape::API
    include PaginationParams

    before { authenticate! }

    NOTEABLE_TYPES = [Issue, MergeRequest, Snippet].freeze

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: { id: %r{[^/]+} } do
      NOTEABLE_TYPES.each do |noteable_type|
        noteables_str = noteable_type.to_s.underscore.pluralize

        desc 'Get a list of project +noteable+ notes' do
          success Entities::Note
        end
        params do
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
          use :pagination
        end
        get ":id/#{noteables_str}/:noteable_id/notes" do
          noteable = find_project_noteable(noteables_str, params[:noteable_id])

          if can?(current_user, noteable_read_ability_name(noteable), noteable)
            # We exclude notes that are cross-references and that cannot be viewed
            # by the current user. By doing this exclusion at this level and not
            # at the DB query level (which we cannot in that case), the current
            # page can have less elements than :per_page even if
            # there's more than one page.
            notes =
              # paginate() only works with a relation. This could lead to a
              # mismatch between the pagination headers info and the actual notes
              # array returned, but this is really a edge-case.
              paginate(noteable.notes)
              .reject { |n| n.cross_reference_not_visible_for?(current_user) }
            present notes, with: Entities::Note
          else
            not_found!("Notes")
          end
        end

        desc 'Get a single +noteable+ note' do
          success Entities::Note
        end
        params do
          requires :note_id, type: Integer, desc: 'The ID of a note'
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
        end
        get ":id/#{noteables_str}/:noteable_id/notes/:note_id" do
          noteable = find_project_noteable(noteables_str, params[:noteable_id])
          note = noteable.notes.find(params[:note_id])
          can_read_note = can?(current_user, noteable_read_ability_name(noteable), noteable) && !note.cross_reference_not_visible_for?(current_user)

          if can_read_note
            present note, with: Entities::Note
          else
            not_found!("Note")
          end
        end

        desc 'Create a new +noteable+ note' do
          success Entities::Note
        end
        params do
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
          requires :body, type: String, desc: 'The content of a note'
          optional :created_at, type: String, desc: 'The creation date of the note'
        end
        post ":id/#{noteables_str}/:noteable_id/notes" do
          noteable = find_project_noteable(noteables_str, params[:noteable_id])

          opts = {
            note: params[:body],
            noteable_type: noteables_str.classify,
            noteable_id: noteable.id
          }

          if can?(current_user, noteable_read_ability_name(noteable), noteable)
            if params[:created_at] && (current_user.admin? || user_project.owner == current_user)
              opts[:created_at] = params[:created_at]
            end

            note = ::Notes::CreateService.new(user_project, current_user, opts).execute

            if note.valid?
              present note, with: Entities.const_get(note.class.name)
            else
              not_found!("Note #{note.errors.messages}")
            end
          else
            not_found!("Note")
          end
        end

        desc 'Update an existing +noteable+ note' do
          success Entities::Note
        end
        params do
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
          requires :note_id, type: Integer, desc: 'The ID of a note'
          requires :body, type: String, desc: 'The content of a note'
        end
        put ":id/#{noteables_str}/:noteable_id/notes/:note_id" do
          note = user_project.notes.find(params[:note_id])

          authorize! :admin_note, note

          opts = {
            note: params[:body]
          }

          note = ::Notes::UpdateService.new(user_project, current_user, opts).execute(note)

          if note.valid?
            present note, with: Entities::Note
          else
            render_api_error!("Failed to save note #{note.errors.messages}", 400)
          end
        end

        desc 'Delete a +noteable+ note' do
          success Entities::Note
        end
        params do
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
          requires :note_id, type: Integer, desc: 'The ID of a note'
        end
        delete ":id/#{noteables_str}/:noteable_id/notes/:note_id" do
          note = user_project.notes.find(params[:note_id])
          authorize! :admin_note, note

          status 204
          ::Notes::DestroyService.new(user_project, current_user).execute(note)
        end
      end
    end

    helpers do
      def find_project_noteable(noteables_str, noteable_id)
        public_send("find_project_#{noteables_str.singularize}", noteable_id)
      end

      def noteable_read_ability_name(noteable)
        "read_#{noteable.class.to_s.underscore}".to_sym
      end
    end
  end
end
