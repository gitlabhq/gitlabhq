module API
  class Pipelines < Grape::API
    before { authenticate! }

    params do
      requires :id, type: String, desc: 'The project ID'
    end
    resource :projects do
      desc 'Get all Pipelines of the project' do
        detail 'This feature was introduced in GitLab 8.11.'
        success Entities::Pipeline
      end
      params do
        optional :page,     type: Integer, desc: 'Page number of the current request'
        optional :per_page, type: Integer, desc: 'Number of items per page'
      end
      get ':id/pipelines' do
        authorize! :read_pipeline, user_project

        present paginate(user_project.pipelines), with: Entities::Pipeline
      end

      desc 'Gets a specific pipeline for the project' do
        detail 'This feature was introduced in GitLab 8.11'
        success Entities::Pipeline
      end
      params do
        requires :pipeline_id, type: Integer, desc: 'The pipeline ID'
      end
      get ':id/pipelines/:pipeline_id' do
        authorize! :read_pipeline, user_project

        present pipeline, with: Entities::Pipeline
      end

      desc 'Retry failed builds in the pipeline' do
        detail 'This feature was introduced in GitLab 8.11.'
        success Entities::Pipeline
      end
      params do
        requires :pipeline_id, type: Integer,  desc: 'The pipeline ID'
      end
      post ':id/pipelines/:pipeline_id/retry' do
        authorize! :update_pipeline, user_project

        pipeline.retry_failed(current_user)

        present pipeline, with: Entities::Pipeline
      end

      desc 'Cancel all builds in the pipeline' do
        detail 'This feature was introduced in GitLab 8.11.'
        success Entities::Pipeline
      end
      params do
        requires :pipeline_id, type: Integer,  desc: 'The pipeline ID'
      end
      post ':id/pipelines/:pipeline_id/cancel' do
        authorize! :update_pipeline, user_project

        pipeline.cancel_running

        status 200
        present pipeline.reload, with: Entities::Pipeline
      end
    end

    helpers do
      def pipeline
        @pipeline ||= user_project.pipelines.find(params[:pipeline_id])
      end
    end
  end
end
