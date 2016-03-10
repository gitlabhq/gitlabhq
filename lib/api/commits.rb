require 'mime/types'

module API
  # Projects commits API
  class Commits < Grape::API
    before { authenticate! }
    before { authorize! :download_code, user_project }

    resource :projects do
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
        commit = user_project.commit(sha)
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
        commit = user_project.commit(sha)
        not_found! "Commit" unless commit
        commit.diffs.to_a
      end

      # Get a commit's comments
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   sha (required) - The commit hash
      # Examples:
      #   GET /projects/:id/repository/commits/:sha/comments
      get ':id/repository/commits/:sha/comments' do
        sha = params[:sha]
        commit = user_project.commit(sha)
        not_found! 'Commit' unless commit
        notes = Note.where(commit_id: commit.id).order(:created_at)
        present paginate(notes), with: Entities::CommitNote
      end

      # Post comment to commit
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   sha (required) - The commit hash
      #   note (required) - Text of comment
      #   path (optional) - The file path
      #   line (optional) - The line number
      #   line_type (optional) - The type of line (new or old)
      # Examples:
      #   POST /projects/:id/repository/commits/:sha/comments
      post ':id/repository/commits/:sha/comments' do
        required_attributes! [:note]

        sha = params[:sha]
        commit = user_project.commit(sha)
        not_found! 'Commit' unless commit
        opts = {
          note: params[:note],
          noteable_type: 'Commit',
          commit_id: commit.id
        }

        if params[:path] && params[:line] && params[:line_type]
          commit.diffs(all_diffs: true).each do |diff|
            next unless diff.new_path == params[:path]
            lines = Gitlab::Diff::Parser.new.parse(diff.diff.each_line)

            lines.each do |line|
              next unless line.new_pos == params[:line].to_i && line.type == params[:line_type]
              break opts[:line_code] = Gitlab::Diff::LineCode.generate(diff.new_path, line.new_pos, line.old_pos)
            end

            break if opts[:line_code]
          end
        end

        note = ::Notes::CreateService.new(user_project, current_user, opts).execute

        if note.save
          present note, with: Entities::CommitNote
        else
          render_api_error!("Failed to save note #{note.errors.messages}", 400)
        end
      end
    end
  end
end
