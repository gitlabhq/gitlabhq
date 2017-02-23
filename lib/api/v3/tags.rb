module API
  module V3
    class Tags < Grape::API
      before { authorize! :download_code, user_project }

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects do
        desc 'Get a project repository tags' do
          success ::API::Entities::RepoTag
        end
        get ":id/repository/tags" do
          tags = user_project.repository.tags.sort_by(&:name).reverse
          present tags, with: ::API::Entities::RepoTag, project: user_project
        end
      end
    end
  end
end
