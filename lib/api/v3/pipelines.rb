module API
  module V3
    class Pipelines < Grape::API
      include PaginationParams

      before { authenticate! }

      params do
        requires :id, type: String, desc: 'The project ID'
      end
      resource :projects, requirements: { id: %r{[^/]+} } do
        desc 'Get all Pipelines of the project' do
          detail 'This feature was introduced in GitLab 8.11.'
          success ::API::Entities::Pipeline
        end
        params do
          use :pagination
          optional :scope,    type: String, values: %w(running branches tags),
                              desc: 'Either running, branches, or tags'
        end
        get ':id/pipelines' do
          Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42123')

          authorize! :read_pipeline, user_project

          pipelines = PipelinesFinder.new(user_project, scope: params[:scope]).execute
          present paginate(pipelines), with: ::API::Entities::Pipeline
        end
      end

      helpers do
        def pipeline
          @pipeline ||= user_project.pipelines.find(params[:pipeline_id])
        end
      end
    end
  end
end
