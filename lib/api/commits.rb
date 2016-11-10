require 'mime/types'

module API
  # Projects commits API
  class Commits < Grape::API
    before { authenticate! }
    before { authorize! :download_code, user_project }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects do
      desc 'Get a project repository commits' do
        success Entities::RepoCommit
      end
      params do
        optional :ref_name, type: String, desc: 'The name of a repository branch or tag, if not given the default branch is used'
        optional :since,    type: String, desc: 'Only commits after or in this date will be returned'
        optional :until,    type: String, desc: 'Only commits before or in this date will be returned'
        optional :page,     type: Integer, default: 0, desc: 'The page for pagination'
        optional :per_page, type: Integer, default: 20, desc: 'The number of results per page'
        optional :path,     type: String, desc: 'The file path'
      end
      get ":id/repository/commits" do
        # TODO remove the next line for 9.0, use DateTime type in the params block
        datetime_attributes! :since, :until

        ref = params[:ref_name] || user_project.try(:default_branch) || 'master'
        offset = params[:page] * params[:per_page]

        commits = user_project.repository.commits(ref,
                                                  path: params[:path],
                                                  limit: params[:per_page],
                                                  offset: offset,
                                                  after: params[:since],
                                                  before: params[:until])

        present commits, with: Entities::RepoCommit
      end

      desc 'Commit multiple file changes as one commit' do
        success Entities::RepoCommitDetail
        detail 'This feature was introduced in GitLab 8.13'
      end
      params do
        requires :id, type: Integer, desc: 'The project ID'
        requires :branch_name, type: String, desc: 'The name of branch'
        requires :commit_message, type: String, desc: 'Commit message'
        requires :actions, type: Array, desc: 'Actions to perform in commit'
        optional :author_email, type: String, desc: 'Author email for commit'
        optional :author_name, type: String, desc: 'Author name for commit'
      end
      post ":id/repository/commits" do
        authorize! :push_code, user_project

        attrs = declared(params)
        attrs[:source_branch] = attrs[:branch_name]
        attrs[:target_branch] = attrs[:branch_name]
        attrs[:actions].map! do |action|
          action[:action] = action[:action].to_sym
          action[:file_path].slice!(0) if action[:file_path] && action[:file_path].start_with?('/')
          action[:previous_path].slice!(0) if action[:previous_path] && action[:previous_path].start_with?('/')
          action
        end

        result = ::Files::MultiService.new(user_project, current_user, attrs).execute

        if result[:status] == :success
          commit_detail = user_project.repository.commits(result[:result], limit: 1).first
          present commit_detail, with: Entities::RepoCommitDetail
        else
          render_api_error!(result[:message], 400)
        end
      end

      desc 'Get a specific commit of a project' do
        success Entities::RepoCommitDetail
        failure [[404, 'Not Found']]
      end
      params do
        requires :sha, type: String, desc: 'A commit sha, or the name of a branch or tag'
      end
      get ":id/repository/commits/:sha" do
        commit = user_project.commit(params[:sha])

        not_found! "Commit" unless commit

        present commit, with: Entities::RepoCommitDetail
      end

      desc 'Get the diff for a specific commit of a project' do
        failure [[404, 'Not Found']]
      end
      params do
        requires :sha, type: String, desc: 'A commit sha, or the name of a branch or tag'
      end
      get ":id/repository/commits/:sha/diff" do
        commit = user_project.commit(params[:sha])

        not_found! "Commit" unless commit

        commit.raw_diffs.to_a
      end

      desc "Get a commit's comments" do
        success Entities::CommitNote
        failure [[404, 'Not Found']]
      end
      params do
        requires :sha, type: String, desc: 'A commit sha, or the name of a branch or tag'
        optional :per_page, type: Integer, desc: 'The amount of items per page for paginaion'
        optional :page, type: Integer, desc: 'The page number for pagination'
      end
      get ':id/repository/commits/:sha/comments' do
        commit = user_project.commit(params[:sha])

        not_found! 'Commit' unless commit
        notes = Note.where(commit_id: commit.id).order(:created_at)

        present paginate(notes), with: Entities::CommitNote
      end

      desc 'Post comment to commit' do
        success Entities::CommitNote
      end
      params do
        requires :sha, type: String, regexp: /\A\h{6,40}\z/, desc: "The commit's SHA"
        requires :note, type: String, desc: 'The text of the comment'
        optional :path, type: String, desc: 'The file path'
        given :path do
          requires :line, type: Integer, desc: 'The line number'
          requires :line_type, type: String, values: ['new', 'old'], default: 'new', desc: 'The type of the line'
        end
      end
      post ':id/repository/commits/:sha/comments' do
        commit = user_project.commit(params[:sha])
        not_found! 'Commit' unless commit

        opts = {
          note: params[:note],
          noteable_type: 'Commit',
          commit_id: commit.id
        }

        if params[:path]
          commit.raw_diffs(all_diffs: true).each do |diff|
            next unless diff.new_path == params[:path]
            lines = Gitlab::Diff::Parser.new.parse(diff.diff.each_line)

            lines.each do |line|
              next unless line.new_pos == params[:line] && line.type == params[:line_type]
              break opts[:line_code] = Gitlab::Diff::LineCode.generate(diff.new_path, line.new_pos, line.old_pos)
            end

            break if opts[:line_code]
          end

          opts[:type] = LegacyDiffNote.name if opts[:line_code]
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
