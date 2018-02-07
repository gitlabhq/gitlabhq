require 'mime/types'

module API
  module V3
    class Commits < Grape::API
      include PaginationParams

      before { authenticate! }
      before { authorize! :download_code, user_project }

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
        desc 'Get a project repository commits' do
          success ::API::Entities::Commit
        end
        params do
          optional :ref_name, type: String, desc: 'The name of a repository branch or tag, if not given the default branch is used'
          optional :since,    type: DateTime, desc: 'Only commits after or in this date will be returned'
          optional :until,    type: DateTime, desc: 'Only commits before or in this date will be returned'
          optional :page,     type: Integer, default: 0, desc: 'The page for pagination'
          optional :per_page, type: Integer, default: 20, desc: 'The number of results per page'
          optional :path,     type: String, desc: 'The file path'
        end
        get ":id/repository/commits" do
          ref = params[:ref_name] || user_project.try(:default_branch) || 'master'
          offset = params[:page] * params[:per_page]

          commits = user_project.repository.commits(ref,
                                                    path: params[:path],
                                                    limit: params[:per_page],
                                                    offset: offset,
                                                    after: params[:since],
                                                    before: params[:until])

          present commits, with: ::API::Entities::Commit
        end

        desc 'Commit multiple file changes as one commit' do
          success ::API::Entities::CommitDetail
          detail 'This feature was introduced in GitLab 8.13'
        end
        params do
          requires :branch_name, type: String, desc: 'The name of branch'
          requires :commit_message, type: String, desc: 'Commit message'
          requires :actions, type: Array[Hash], desc: 'Actions to perform in commit'
          optional :author_email, type: String, desc: 'Author email for commit'
          optional :author_name, type: String, desc: 'Author name for commit'
        end
        post ":id/repository/commits" do
          authorize! :push_code, user_project

          attrs = declared_params.dup
          branch = attrs.delete(:branch_name)
          attrs.merge!(start_branch: branch, branch_name: branch)

          result = ::Files::MultiService.new(user_project, current_user, attrs).execute

          if result[:status] == :success
            commit_detail = user_project.repository.commits(result[:result], limit: 1).first
            present commit_detail, with: ::API::Entities::CommitDetail
          else
            render_api_error!(result[:message], 400)
          end
        end

        desc 'Get a specific commit of a project' do
          success ::API::Entities::CommitDetail
          failure [[404, 'Not Found']]
        end
        params do
          requires :sha, type: String, desc: 'A commit sha, or the name of a branch or tag'
          optional :stats, type: Boolean, default: true, desc: 'Include commit stats'
        end
        get ":id/repository/commits/:sha", requirements: API::COMMIT_ENDPOINT_REQUIREMENTS do
          commit = user_project.commit(params[:sha])

          not_found! "Commit" unless commit

          present commit, with: ::API::Entities::CommitDetail, stats: params[:stats]
        end

        desc 'Get the diff for a specific commit of a project' do
          failure [[404, 'Not Found']]
        end
        params do
          requires :sha, type: String, desc: 'A commit sha, or the name of a branch or tag'
        end
        get ":id/repository/commits/:sha/diff", requirements: API::COMMIT_ENDPOINT_REQUIREMENTS do
          commit = user_project.commit(params[:sha])

          not_found! "Commit" unless commit

          commit.raw_diffs.to_a
        end

        desc "Get a commit's comments" do
          success ::API::Entities::CommitNote
          failure [[404, 'Not Found']]
        end
        params do
          use :pagination
          requires :sha, type: String, desc: 'A commit sha, or the name of a branch or tag'
        end
        get ':id/repository/commits/:sha/comments', requirements: API::COMMIT_ENDPOINT_REQUIREMENTS do
          commit = user_project.commit(params[:sha])

          not_found! 'Commit' unless commit
          notes = commit.notes.order(:created_at)

          present paginate(notes), with: ::API::Entities::CommitNote
        end

        desc 'Cherry pick commit into a branch' do
          detail 'This feature was introduced in GitLab 8.15'
          success ::API::Entities::Commit
        end
        params do
          requires :sha, type: String, desc: 'A commit sha to be cherry picked'
          requires :branch, type: String, desc: 'The name of the branch'
        end
        post ':id/repository/commits/:sha/cherry_pick', requirements: API::COMMIT_ENDPOINT_REQUIREMENTS do
          authorize! :push_code, user_project

          commit = user_project.commit(params[:sha])
          not_found!('Commit') unless commit

          branch = user_project.repository.find_branch(params[:branch])
          not_found!('Branch') unless branch

          commit_params = {
            commit: commit,
            start_branch: params[:branch],
            branch_name: params[:branch]
          }

          result = ::Commits::CherryPickService.new(user_project, current_user, commit_params).execute

          if result[:status] == :success
            branch = user_project.repository.find_branch(params[:branch])
            present user_project.repository.commit(branch.dereferenced_target), with: ::API::Entities::Commit
          else
            render_api_error!(result[:message], 400)
          end
        end

        desc 'Post comment to commit' do
          success ::API::Entities::CommitNote
        end
        params do
          requires :sha, type: String, regexp: /\A\h{6,40}\z/, desc: "The commit's SHA"
          requires :note, type: String, desc: 'The text of the comment'
          optional :path, type: String, desc: 'The file path'
          given :path do
            requires :line, type: Integer, desc: 'The line number'
            requires :line_type, type: String, values: %w(new old), default: 'new', desc: 'The type of the line'
          end
        end
        post ':id/repository/commits/:sha/comments', requirements: API::COMMIT_ENDPOINT_REQUIREMENTS do
          commit = user_project.commit(params[:sha])
          not_found! 'Commit' unless commit

          opts = {
            note: params[:note],
            noteable_type: 'Commit',
            commit_id: commit.id
          }

          if params[:path]
            commit.raw_diffs(limits: false).each do |diff|
              next unless diff.new_path == params[:path]

              lines = Gitlab::Diff::Parser.new.parse(diff.diff.each_line)

              lines.each do |line|
                next unless line.new_pos == params[:line] && line.type == params[:line_type]

                break opts[:line_code] = Gitlab::Git.diff_line_code(diff.new_path, line.new_pos, line.old_pos)
              end

              break if opts[:line_code]
            end

            opts[:type] = LegacyDiffNote.name if opts[:line_code]
          end

          note = ::Notes::CreateService.new(user_project, current_user, opts).execute

          if note.save
            present note, with: ::API::Entities::CommitNote
          else
            render_api_error!("Failed to save note #{note.errors.messages}", 400)
          end
        end
      end
    end
  end
end
