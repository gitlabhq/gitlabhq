module API
  module V3
    class Runners < Grape::API
      include PaginationParams

      before { authenticate! }

      resource :runners do
        desc 'Remove a runner' do
          success ::API::Entities::Runner
        end
        params do
          requires :id, type: Integer, desc: 'The ID of the runner'
        end
        delete ':id' do
          runner = Ci::Runner.find(params[:id])
          not_found!('Runner') unless runner

          authenticate_delete_runner!(runner)

          status(200)
          runner.destroy
        end
      end

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects, requirements: { id: %r{[^/]+} } do
        before { authorize_admin_project }

        desc "Disable project's runner" do
          success ::API::Entities::Runner
        end
        params do
          requires :runner_id, type: Integer, desc: 'The ID of the runner'
        end
        delete ':id/runners/:runner_id' do
          runner_project = user_project.runner_projects.find_by(runner_id: params[:runner_id])
          not_found!('Runner') unless runner_project

          runner = runner_project.runner
          forbidden!("Only one project associated with the runner. Please remove the runner instead") if runner.projects.count == 1

          runner_project.destroy

          present runner, with: ::API::Entities::Runner
        end
      end

      helpers do
        def authenticate_delete_runner!(runner)
          return if current_user.admin?

          forbidden!("Runner is shared") if runner.is_shared?
          forbidden!("Runner associated with more than one project") if runner.projects.count > 1
          forbidden!("No access granted") unless user_can_access_runner?(runner)
        end

        def user_can_access_runner?(runner)
          current_user.ci_authorized_runners.exists?(runner.id)
        end
      end
    end
  end
end
