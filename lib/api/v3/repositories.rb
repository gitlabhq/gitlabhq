require 'mime/types'

module API
  module V3
    class Repositories < Grape::API
      before { authorize! :download_code, user_project }

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects do
        helpers do
          def handle_project_member_errors(errors)
            if errors[:project_access].any?
              error!(errors[:project_access], 422)
            end
            not_found!
          end
        end

        desc 'Get a project repository tree' do
          success ::API::Entities::RepoTreeObject
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

          present tree.sorted_entries, with: ::API::Entities::RepoTreeObject
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
