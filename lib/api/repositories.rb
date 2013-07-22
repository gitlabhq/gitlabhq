module API
  # Projects API
  class Repositories < Grape::API
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

      # Get a project repository branches
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   GET /projects/:id/repository/branches
      get ":id/repository/branches" do
        present user_project.repo.heads.sort_by(&:name), with: Entities::RepoObject, project: user_project
      end


      # Create a branch
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   branch (required) - The name of the branch
      #   ref (required) - SHA1 ref of branch.
      # Example Request:
      #   POST /projects/:id/repository/branches/:branch/:ref
      post ":id/repository/branches/:branch/:ref",
        :requirements => { :branch => /.*/, :ref => /.*/ } do

        @branch = user_project.repo.heads.find { |item| item.name == params[:branch] }
        resource_exists! if @branch

        user_project.repository.create_branch(params[:branch], params[:ref])
        @branch = user_project.repo.heads.find { |item| item.name == params[:branch] }

        # Return 200 OK. Since the branch is created in a background process
        present({ 'received' => true })
      end

      # Deletes a branch
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   branch (required) - The name of the branch
      # Example Request:
      #   DELETE /projects/:id/repository/branches/:branch
      delete ":id/repository/branches/:branch",
        :requirements => { :branch => /.*/ } do
        @branch = user_project.repo.heads.find { |item| item.name == params[:branch] }
        not_found! unless @branch

        user_project.repository.rm_branch(params[:branch])
        # Returns 200 OK
        present({ 'received' => true })
      end

      # Get a single branch
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   branch (required) - The name of the branch
      # Example Request:
      #   GET /projects/:id/repository/branches/:branch
      get ":id/repository/branches/:branch" do
        @branch = user_project.repo.heads.find { |item| item.name == params[:branch] }
        not_found!("Branch does not exist") if @branch.nil?
        present @branch, with: Entities::RepoObject, project: user_project
      end

      # Protect a single branch
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   branch (required) - The name of the branch
      # Example Request:
      #   PUT /projects/:id/repository/branches/:branch/protect
      put ":id/repository/branches/:branch/protect" do
        @branch = user_project.repo.heads.find { |item| item.name == params[:branch] }
        not_found! unless @branch
        protected = user_project.protected_branches.find_by_name(@branch.name)

        unless protected
          user_project.protected_branches.create(name: @branch.name)
        end

        present @branch, with: Entities::RepoObject, project: user_project
      end

      # Unprotect a single branch
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   branch (required) - The name of the branch
      # Example Request:
      #   PUT /projects/:id/repository/branches/:branch/unprotect
      put ":id/repository/branches/:branch/unprotect" do
        @branch = user_project.repo.heads.find { |item| item.name == params[:branch] }
        not_found! unless @branch
        protected = user_project.protected_branches.find_by_name(@branch.name)

        if protected
          protected.destroy
        end

        present @branch, with: Entities::RepoObject, project: user_project
      end

      # Get a project repository tags
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   GET /projects/:id/repository/tags
      get ":id/repository/tags" do
        present user_project.repo.tags.sort_by(&:name).reverse, with: Entities::RepoObject
      end

      # Create a tag
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   tag (required) - The name of the tag
      #   ref (required) - SHA1 ref of tag.
      # Example Request:
      #   POST /projects/:id/repository/tags/:tag/:ref
      post ":id/repository/tags/:tag/:ref",
        :requirements => { :tag => /.*/, :ref => /.*/ } do
        @tag = user_project.repo.tags.find { |item| item.name == params[:tag] }
        resource_exists! if @tag

        user_project.repository.create_tag(params[:tag], params[:ref])
        @tag = user_project.repo.tags.find { |item| item.name == params[:tag] }

        # Return 200 OK. Since the tag is created in a background process
        # we can't yet return it.
        present({ 'received' => true })
      end

      # Deletes a tag
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   tag (required) - The name of the tag
      # Example Request:
      #   DELETE /projects/:id/repository/tags/:tag
      delete ":id/repository/tags/:tag",
        :requirements => { :tag => /.*/ } do
        @tag = user_project.repo.tags.find { |item| item.name == params[:tag] }
        not_found! unless @tag

        user_project.repository.rm_tag(params[:tag])
        # Returns 200 OK
        present({ 'received' => true })
      end

      # Get a project repository commits
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   ref_name (optional) - The name of a repository branch or tag, if not given the default branch is used
      # Example Request:
      #   GET /projects/:id/repository/commits
      get ":id/repository/commits" do
        authorize! :download_code, user_project

        page = (params[:page] || 0).to_i
        per_page = (params[:per_page] || 20).to_i
        ref = params[:ref_name] || user_project.try(:default_branch) || 'master'

        commits = user_project.repository.commits(ref, nil, per_page, page * per_page)
        present commits, with: Entities::RepoCommit
      end

      # Get a specific commit of a project
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   sha (required) - The commit hash or name of a repository branch or tag
      # Example Request:
      #   GET /projects/:id/repository/commits/:sha
      get ":id/repository/commits/:sha" do
        authorize! :download_code, user_project
        sha = params[:sha]
        commit = user_project.repository.commit(sha)
        not_found! "Commit" unless commit
        present commit, with: Entities::RepoCommit
      end

      # Get the diff for a specific commit of a project
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   sha (required) - The commit or branch name
      # Example Request:
      #   GET /projects/:id/repository/commits/:sha/diff
      get ":id/repository/commits/:sha/diff" do
        authorize! :download_code, user_project
        sha = params[:sha]
        result = CommitLoadContext.new(user_project, current_user, {id: sha}).execute
        not_found! "Commit" unless result[:commit]
        result[:commit].diffs
      end

      # Get a project repository tree
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   ref_name (optional) - The name of a repository branch or tag, if not given the default branch is used
      # Example Request:
      #   GET /projects/:id/repository/tree
      get ":id/repository/tree" do
        authorize! :download_code, user_project

        ref = params[:ref_name] || user_project.try(:default_branch) || 'master'
        path = params[:path] || nil

        commit = user_project.repository.commit(ref)
        tree = Tree.new(user_project.repository, commit.id, ref, path)

        trees = []

        %w(trees blobs submodules).each do |type|
          trees += tree.send(type).map { |t| { name: t.name, type: type.singularize, mode: t.mode, id: t.id } }
        end

        trees
      end

      # Get a raw file contents
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   sha (required) - The commit or branch name
      #   filepath (required) - The path to the file to display
      # Example Request:
      #   GET /projects/:id/repository/blobs/:sha
      get [ ":id/repository/blobs/:sha", ":id/repository/commits/:sha/blob" ] do
        authorize! :download_code, user_project
        required_attributes! [:filepath]

        ref = params[:sha]

        repo = user_project.repository

        commit = repo.commit(ref)
        not_found! "Commit" unless commit

        blob = Gitlab::Git::Blob.new(repo, commit.id, ref, params[:filepath])
        not_found! "File" unless blob.exists?

        env['api.format'] = :txt

        content_type blob.mime_type
        present blob.data
      end
    end
  end
end

