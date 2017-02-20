require 'mime/types'

module API
  module V3
    class Branches < Grape::API
      before { authenticate! }
      before { authorize! :download_code, user_project }

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects do
        desc 'Get a project repository branches' do
          success ::API::Entities::RepoBranch
        end
        get ":id/repository/branches" do
          branches = user_project.repository.branches.sort_by(&:name)

          present branches, with: ::API::Entities::RepoBranch, project: user_project
        end
      end
    end
  end
end
