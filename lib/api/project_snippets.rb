module API
  # Projects API
  class ProjectSnippets < Grape::API
    before { authenticate! }

    resource :projects do
      helpers do
        def handle_project_member_errors(errors)
          if errors[:project_access].any?
            error!(errors[:project_access], 422)
          end
          not_found!
        end
      end

      # Get a project snippets
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   GET /projects/:id/snippets
      get ":id/snippets" do
        present paginate(user_project.snippets), with: Entities::ProjectSnippet
      end

      # Get a project snippet
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   snippet_id (required) - The ID of a project snippet
      # Example Request:
      #   GET /projects/:id/snippets/:snippet_id
      get ":id/snippets/:snippet_id" do
        @snippet = user_project.snippets.find(params[:snippet_id])
        present @snippet, with: Entities::ProjectSnippet
      end

      # Create a new project snippet
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   title (required) - The title of a snippet
      #   file_name (required) - The name of a snippet file
      #   code (required) - The content of a snippet
      #   visibility_level (required) - The snippet's visibility
      # Example Request:
      #   POST /projects/:id/snippets
      post ":id/snippets" do
        authorize! :create_project_snippet, user_project
        required_attributes! [:title, :file_name, :code, :visibility_level]

        attrs = attributes_for_keys [:title, :file_name, :visibility_level]
        attrs[:content] = params[:code] if params[:code].present?
        @snippet = CreateSnippetService.new(user_project, current_user,
                                            attrs).execute

        if @snippet.errors.any?
          render_validation_error!(@snippet)
        else
          present @snippet, with: Entities::ProjectSnippet
        end
      end

      # Update an existing project snippet
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   snippet_id (required) - The ID of a project snippet
      #   title (optional) - The title of a snippet
      #   file_name (optional) - The name of a snippet file
      #   code (optional) - The content of a snippet
      #   visibility_level (optional) - The snippet's visibility
      # Example Request:
      #   PUT /projects/:id/snippets/:snippet_id
      put ":id/snippets/:snippet_id" do
        @snippet = user_project.snippets.find(params[:snippet_id])
        authorize! :update_project_snippet, @snippet

        attrs = attributes_for_keys [:title, :file_name, :visibility_level]
        attrs[:content] = params[:code] if params[:code].present?

        UpdateSnippetService.new(user_project, current_user, @snippet,
                                 attrs).execute
        if @snippet.errors.any?
          render_validation_error!(@snippet)
        else
          present @snippet, with: Entities::ProjectSnippet
        end
      end

      # Delete a project snippet
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   snippet_id (required) - The ID of a project snippet
      # Example Request:
      #   DELETE /projects/:id/snippets/:snippet_id
      delete ":id/snippets/:snippet_id" do
        begin
          @snippet = user_project.snippets.find(params[:snippet_id])
          authorize! :update_project_snippet, @snippet
          @snippet.destroy
        rescue
          not_found!('Snippet')
        end
      end

      # Get a raw project snippet
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   snippet_id (required) - The ID of a project snippet
      # Example Request:
      #   GET /projects/:id/snippets/:snippet_id/raw
      get ":id/snippets/:snippet_id/raw" do
        @snippet = user_project.snippets.find(params[:snippet_id])

        env['api.format'] = :txt
        content_type 'text/plain'
        present @snippet.content
      end
    end
  end
end
