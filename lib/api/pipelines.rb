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
        optional :scope,    type: String, values: ['running', 'branches', 'tags'],
                            desc: 'Either running, branches, or tags'
      end
      get ':id/pipelines' do
        authorize! :read_pipeline, user_project

        pipelines = PipelinesFinder.new(user_project).execute(scope: params[:scope])
        present paginate(pipelines), with: Entities::Pipeline
      end
      
      desc 'Create a new pipeline' do
        detail 'This feature was introduced in GitLab 8.14'
        success Entities::Pipeline
      end
      params do
        requires :ref, type: String,  desc: 'Reference'
      end
      post ':id/pipeline' do
        authorize! :create_pipeline, user_project

        new_pipeline = Ci::CreatePipelineService.new(user_project,
                                                     current_user,
                                                     declared_params(include_missing: false))
                           .execute(ignore_skip_ci: true, save_on_errors: false)
        if new_pipeline.persisted?
          present new_pipeline, with: Entities::Pipeline
        else
          render_validation_error!(new_pipeline)
        end
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
