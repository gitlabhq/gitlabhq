require 'mime/types'

module API
  module V3
    class Repositories < Grape::API
      before { authorize! :download_code, user_project }

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
        helpers do
          def handle_project_member_errors(errors)
            if errors[:project_access].any?
              error!(errors[:project_access], 422)
            end

            not_found!
          end
        end

        desc 'Get a project repository tree' do
          success ::API::Entities::TreeObject
        end
        params do
          optional :ref_name, type: String, desc: 'The name of a repository branch or tag, if not given the default branch is used'
          optional :path, type: String, desc: 'The path of the tree'
          optional :recursive, type: Boolean, default: false, desc: 'Used to get a recursive tree'
        end
        get ':id/repository/tree' do
          ref = params[:ref_name] || user_project.try(:default_branch) || 'master'
          path = params[:path] || nil

          commit = user_project.commit(ref)
          not_found!('Tree') unless commit

          tree = user_project.repository.tree(commit.id, path, recursive: params[:recursive])

          present tree.sorted_entries, with: ::API::Entities::TreeObject
        end

        desc 'Get a raw file contents'
        params do
          requires :sha, type: String, desc: 'The commit, branch name, or tag name'
          requires :filepath, type: String, desc: 'The path to the file to display'
        end
        get [":id/repository/blobs/:sha", ":id/repository/commits/:sha/blob"], requirements: API::COMMIT_ENDPOINT_REQUIREMENTS do
          repo = user_project.repository
          commit = repo.commit(params[:sha])
          not_found! "Commit" unless commit
          blob = Gitlab::Git::Blob.find(repo, commit.id, params[:filepath])
          not_found! "File" unless blob
          send_git_blob repo, blob
        end

        desc 'Get a raw blob contents by blob sha'
        params do
          requires :sha, type: String, desc: 'The commit, branch name, or tag name'
        end
        get ':id/repository/raw_blobs/:sha', requirements: API::COMMIT_ENDPOINT_REQUIREMENTS do
          repo = user_project.repository
          begin
            blob = Gitlab::Git::Blob.raw(repo, params[:sha])
          rescue
            not_found! 'Blob'
          end
          not_found! 'Blob' unless blob
          send_git_blob repo, blob
        end

        desc 'Get an archive of the repository'
        params do
          optional :sha, type: String, desc: 'The commit sha of the archive to be downloaded'
          optional :format, type: String, desc: 'The archive format'
        end
        get ':id/repository/archive', requirements: { format: Gitlab::PathRegex.archive_formats_regex } do
          begin
            send_git_archive user_project.repository, ref: params[:sha], format: params[:format]
          rescue
            not_found!('File')
          end
        end

        desc 'Compare two branches, tags, or commits' do
          success ::API::Entities::Compare
        end
        params do
          requires :from, type: String, desc: 'The commit, branch name, or tag name to start comparison'
          requires :to, type: String, desc: 'The commit, branch name, or tag name to stop comparison'
        end
        get ':id/repository/compare' do
          compare = Gitlab::Git::Compare.new(user_project.repository.raw_repository, params[:from], params[:to])
          present compare, with: ::API::Entities::Compare
        end

        desc 'Get repository contributors' do
          success ::API::Entities::Contributor
        end
        get ':id/repository/contributors' do
          begin
            present user_project.repository.contributors,
                    with: ::API::Entities::Contributor
          rescue
            not_found!
          end
        end
      end
    end
  end
end
