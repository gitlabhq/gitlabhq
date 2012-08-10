module Gitlab
  # Projects API
  class Projects < Grape::API
    before { authenticate! }

    resource :projects do
      # Get a projects list for authenticated user
      #
      # Example Request:
      #   GET /projects
      get do
        @projects = current_user.projects
        present @projects, with: Entities::Project
      end

      # Get a single project
      #
      # Parameters:
      #   id (required) - The ID or code name of a project
      # Example Request:
      #   GET /projects/:id
      get ":id" do
        present user_project, with: Entities::Project
      end

      # Get a project repository branches
      #
      # Parameters:
      #   id (required) - The ID or code name of a project
      # Example Request:
      #   GET /projects/:id/repository/branches
      get ":id/repository/branches" do
        present user_project.repo.heads.sort_by(&:name), with: Entities::RepoObject
      end

      # Get a single branch
      #
      # Parameters:
      #   id (required) - The ID or code name of a project
      #   branch (required) - The name of the branch
      # Example Request:
      #   GET /projects/:id/repository/branches/:branch
      get ":id/repository/branches/:branch" do
        @branch = user_project.repo.heads.find { |item| item.name == params[:branch] }
        present @branch, with: Entities::RepoObject
      end

      # Get a project repository tags
      #
      # Parameters:
      #   id (required) - The ID or code name of a project
      # Example Request:
      #   GET /projects/:id/repository/tags
      get ":id/repository/tags" do
        present user_project.repo.tags.sort_by(&:name).reverse, with: Entities::RepoObject
      end

      # Get a project snippet
      #
      # Parameters:
      #   id (required) - The ID or code name of a project
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
      #   id (required) - The ID or code name of a project
      #   title (required) - The title of a snippet
      #   file_name (required) - The name of a snippet file
      #   lifetime (optional) - The expiration date of a snippet
      #   code (required) - The content of a snippet
      # Example Request:
      #   POST /projects/:id/snippets
      post ":id/snippets" do
        @snippet = user_project.snippets.new(
          title: params[:title],
          file_name: params[:file_name],
          expires_at: params[:lifetime],
          content: params[:code]
        )
        @snippet.author = current_user

        if @snippet.save
          present @snippet, with: Entities::ProjectSnippet
        else
          error!({'message' => '404 Not found'}, 404)
        end
      end

      # Update an existing project snippet
      #
      # Parameters:
      #   id (required) - The ID or code name of a project
      #   snippet_id (required) - The ID of a project snippet
      #   title (optional) - The title of a snippet
      #   file_name (optional) - The name of a snippet file
      #   lifetime (optional) - The expiration date of a snippet
      #   code (optional) - The content of a snippet
      # Example Request:
      #   PUT /projects/:id/snippets/:snippet_id
      put ":id/snippets/:snippet_id" do
        @snippet = user_project.snippets.find(params[:snippet_id])
        parameters = {
          title: (params[:title] || @snippet.title),
          file_name: (params[:file_name] || @snippet.file_name),
          expires_at: (params[:lifetime] || @snippet.expires_at),
          content: (params[:code] || @snippet.content)
        }

        if @snippet.update_attributes(parameters)
          present @snippet, with: Entities::ProjectSnippet
        else
          error!({'message' => '404 Not found'}, 404)
        end
      end

      # Delete a project snippet
      #
      # Parameters:
      #   id (required) - The ID or code name of a project
      #   snippet_id (required) - The ID of a project snippet
      # Example Request:
      #   DELETE /projects/:id/snippets/:snippet_id
      delete ":id/snippets/:snippet_id" do
        @snippet = user_project.snippets.find(params[:snippet_id])
        @snippet.destroy
      end

      # Get a raw project snippet
      #
      # Parameters:
      #   id (required) - The ID or code name of a project
      #   snippet_id (required) - The ID of a project snippet
      # Example Request:
      #   GET /projects/:id/snippets/:snippet_id/raw
      get ":id/snippets/:snippet_id/raw" do
        @snippet = user_project.snippets.find(params[:snippet_id])
        content_type 'text/plain'
        present @snippet.content
      end

      # Get a raw file contents
      #
      # Parameters:
      #   id (required) - The ID or code name of a project
      #   sha (required) - The commit or branch name
      #   filepath (required) - The path to the file to display
      # Example Request:
      #   GET /projects/:id/repository/commits/:sha/blob
      get ":id/repository/commits/:sha/blob" do
        ref = params[:sha]

        commit = user_project.commit ref
        error!('404 Commit Not Found', 404) unless commit

        tree = Tree.new commit.tree, user_project, ref, params[:filepath]
        error!('404 File Not Found', 404) unless tree.try(:tree)

        if tree.text?
          encoding = Gitlab::Encode.detect_encoding(tree.data)
          content_type encoding ? "text/plain; charset=#{encoding}" : "text/plain"
        else
          content_type tree.mime_type
        end

        present tree.data
      end

    end
  end
end
