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
        @projects = paginate current_user.projects
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

      # Create new project
      #
      # Parameters:
      #   name (required) - name for new project
      #   code (optional) - code for new project, uses project name if not set
      #   path (optional) - path for new project, uses project name if not set
      #   description (optional) - short project description
      #   default_branch (optional) - 'master' by default
      #   issues_enabled (optional) - enabled by default
      #   wall_enabled (optional) - enabled by default
      #   merge_requests_enabled (optional) - enabled by default
      #   wiki_enabled (optional) - enabled by default
      # Example Request
      #   POST /projects
      post do
        params[:code] ||= params[:name]
        params[:path] ||= params[:name]
        project_attrs = {}
        params.each_pair do |k ,v|
          if Project.attribute_names.include? k
            project_attrs[k] = v
          end
        end
        @project = Project.create_by_user(project_attrs, current_user)
        if @project.saved?
          present @project, with: Entities::Project
        else
          not_found!
        end
      end

      # Get project users
      #
      # Parameters:
      #   id (required) - The ID or code name of a project
      # Example Request:
      #   GET /projects/:id/users
      get ":id/users" do
        @users_projects = paginate user_project.users_projects
        present @users_projects, with: Entities::UsersProject
      end

      # Add users to project with specified access level
      #
      # Parameters:
      #   id (required) - The ID or code name of a project
      #   user_ids (required) - The ID list of users to add
      #   project_access (required) - Project access level
      # Example Request:
      #   POST /projects/:id/users
      post ":id/users" do
        authorize! :admin_project, user_project
        user_project.add_users_ids_to_team(params[:user_ids].values, params[:project_access])
        nil
      end

      # Update users to specified access level
      #
      # Parameters:
      #   id (required) - The ID or code name of a project
      #   user_ids (required) - The ID list of users to add
      #   project_access (required) - New project access level to
      # Example Request:
      #   PUT /projects/:id/add_users
      put ":id/users" do
        authorize! :admin_project, user_project
        user_project.update_users_ids_to_role(params[:user_ids].values, params[:project_access])
        nil
      end

      # Delete project users
      #
      # Parameters:
      #   id (required) - The ID or code name of a project
      #   user_ids (required) - The ID list of users to delete
      # Example Request:
      #   DELETE /projects/:id/users
      delete ":id/users" do
        authorize! :admin_project, user_project
        user_project.delete_users_ids_from_team(params[:user_ids].values)
        nil
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
          not_found!
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
        authorize! :modify_snippet, @snippet

        parameters = {
          title: (params[:title] || @snippet.title),
          file_name: (params[:file_name] || @snippet.file_name),
          expires_at: (params[:lifetime] || @snippet.expires_at),
          content: (params[:code] || @snippet.content)
        }

        if @snippet.update_attributes(parameters)
          present @snippet, with: Entities::ProjectSnippet
        else
          not_found!
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
        authorize! :modify_snippet, @snippet

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
        not_found! "Commit" unless commit

        tree = Tree.new commit.tree, user_project, ref, params[:filepath]
        not_found! "File" unless tree.try(:tree)

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
