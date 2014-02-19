require 'mime/types'

module API
  # Projects API
  class Commits < Grape::API
    before { authenticate! }
    before { authorize! :download_code, user_project }

    resource :projects do
      helpers do
        def handle_project_member_errors(errors)
          if errors[:project_access].any?
            error!(errors[:project_access], 422)
          end
          not_found!
        end
      end

      # Get a project repository commits
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   ref_name (optional) - The name of a repository branch or tag, if not given the default branch is used
      # Example Request:
      #   GET /projects/:id/repository/commits
      get ":id/repository/commits" do
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
        sha = params[:sha]
        commit = user_project.repository.commit(sha)
        not_found! "Commit" unless commit
        present commit, with: Entities::RepoCommitDetail
      end

      # Get the diff for a specific commit of a project
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   sha (required) - The commit or branch name
      # Example Request:
      #   GET /projects/:id/repository/commits/:sha/diff
      get ":id/repository/commits/:sha/diff" do
        sha = params[:sha]
        commit = user_project.repository.commit(sha)
        not_found! "Commit" unless commit
        commit.diffs
      end
    end
  end
end
