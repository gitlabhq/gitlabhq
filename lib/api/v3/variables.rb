module API
  module V3
    class Variables < Grape::API
      include PaginationParams

      before { authenticate! }
      before { authorize! :admin_build, user_project }

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end

      resource :projects, requirements: { id: %r{[^/]+} } do
        desc 'Delete an existing variable from a project' do
          success ::API::Entities::Variable
        end
        params do
          requires :key, type: String, desc: 'The key of the variable'
        end
        delete ':id/variables/:key' do
          variable = user_project.variables.find_by(key: params[:key])
          not_found!('Variable') unless variable

          present variable.destroy, with: ::API::Entities::Variable
        end
      end
    end
  end
end
