# frozen_string_literal: true

module API
  module Ci
    class Pipelines < ::API::Base
      include PaginationParams

      before { authenticate_non_get! }

      feature_category :continuous_integration

      params do
        requires :id, type: String, desc: 'The project ID'
      end
      resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Get all Pipelines of the project' do
          detail 'This feature was introduced in GitLab 8.11.'
          success Entities::Ci::PipelineBasic
        end

        helpers do
          params :optional_scope do
            optional :scope, types: [String, Array[String]], desc: 'The scope of builds to show',
                            values: ::CommitStatus::AVAILABLE_STATUSES,
                           coerce_with: ->(scope) {
                             case scope
                             when String
                               [scope]
                             when ::Array
                               scope
                             else
                               ['unknown']
                             end
                           }
          end
        end

        params do
          use :pagination
          optional :scope,    type: String, values: %w[running pending finished branches tags],
                              desc: 'The scope of pipelines'
          optional :status,   type: String, values: ::Ci::HasStatus::AVAILABLE_STATUSES,
                              desc: 'The status of pipelines'
          optional :ref,      type: String, desc: 'The ref of pipelines'
          optional :sha,      type: String, desc: 'The sha of pipelines'
          optional :yaml_errors, type: Boolean, desc: 'Returns pipelines with invalid configurations'
          optional :name,     type: String, desc: 'The name of the user who triggered pipelines'
          optional :username, type: String, desc: 'The username of the user who triggered pipelines'
          optional :updated_before, type: DateTime, desc: 'Return pipelines updated before the specified datetime. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ'
          optional :updated_after, type: DateTime, desc: 'Return pipelines updated after the specified datetime. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ'
          optional :order_by, type: String, values: ::Ci::PipelinesFinder::ALLOWED_INDEXED_COLUMNS, default: 'id',
                              desc: 'Order pipelines'
          optional :sort,     type: String, values: %w[asc desc], default: 'desc',
                              desc: 'Sort pipelines'
        end
        get ':id/pipelines' do
          authorize! :read_pipeline, user_project
          authorize! :read_build, user_project

          pipelines = ::Ci::PipelinesFinder.new(user_project, current_user, params).execute
          present paginate(pipelines), with: Entities::Ci::PipelineBasic
        end

        desc 'Create a new pipeline' do
          detail 'This feature was introduced in GitLab 8.14'
          success Entities::Ci::Pipeline
        end
        params do
          requires :ref, type: String, desc: 'Reference'
          optional :variables, Array, desc: 'Array of variables available in the pipeline'
        end
        post ':id/pipeline' do
          Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20711')

          authorize! :create_pipeline, user_project

          pipeline_params = declared_params(include_missing: false)
            .merge(variables_attributes: params[:variables])
            .except(:variables)

          response = ::Ci::CreatePipelineService.new(user_project, current_user, pipeline_params)
            .execute(:api, ignore_skip_ci: true, save_on_errors: false)
          new_pipeline = response.payload

          if response.success?
            present new_pipeline, with: Entities::Ci::Pipeline
          else
            render_validation_error!(new_pipeline)
          end
        end

        desc 'Gets a the latest pipeline for the project branch' do
          detail 'This feature was introduced in GitLab 12.3'
          success Entities::Ci::Pipeline
        end
        params do
          optional :ref, type: String, desc: 'branch ref of pipeline'
        end
        get ':id/pipelines/latest' do
          authorize! :read_pipeline, latest_pipeline

          present latest_pipeline, with: Entities::Ci::Pipeline
        end

        desc 'Gets a specific pipeline for the project' do
          detail 'This feature was introduced in GitLab 8.11'
          success Entities::Ci::Pipeline
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID'
        end
        get ':id/pipelines/:pipeline_id' do
          authorize! :read_pipeline, pipeline

          present pipeline, with: Entities::Ci::Pipeline
        end

        desc 'Get pipeline jobs' do
          success Entities::Ci::Job
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID'
          optional :include_retried, type: Boolean, default: false, desc: 'Includes retried jobs'
          use :optional_scope
          use :pagination
        end

        get ':id/pipelines/:pipeline_id/jobs' do
          authorize!(:read_pipeline, user_project)

          pipeline = user_project.all_pipelines.find(params[:pipeline_id])

          builds = ::Ci::JobsFinder
            .new(current_user: current_user, pipeline: pipeline, params: params)
            .execute

          builds = builds.with_preloads

          present paginate(builds), with: Entities::Ci::Job
        end

        desc 'Get pipeline bridge jobs' do
          success Entities::Ci::Bridge
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID'
          use :optional_scope
          use :pagination
        end

        get ':id/pipelines/:pipeline_id/bridges' do
          authorize!(:read_build, user_project)

          pipeline = user_project.all_pipelines.find(params[:pipeline_id])

          bridges = ::Ci::JobsFinder
            .new(current_user: current_user, pipeline: pipeline, params: params, type: ::Ci::Bridge)
            .execute
          bridges = bridges.with_preloads

          present paginate(bridges), with: Entities::Ci::Bridge
        end

        desc 'Gets the variables for a given pipeline' do
          detail 'This feature was introduced in GitLab 11.11'
          success Entities::Ci::Variable
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID'
        end
        get ':id/pipelines/:pipeline_id/variables' do
          authorize! :read_pipeline_variable, pipeline

          present pipeline.variables, with: Entities::Ci::Variable
        end

        desc 'Gets the test report for a given pipeline' do
          detail 'This feature was introduced in GitLab 13.0.'
          success TestReportEntity
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID'
        end
        get ':id/pipelines/:pipeline_id/test_report' do
          authorize! :read_build, pipeline

          present pipeline.test_reports, with: TestReportEntity, details: true
        end

        desc 'Deletes a pipeline' do
          detail 'This feature was introduced in GitLab 11.6'
          http_codes [[204, 'Pipeline was deleted'], [403, 'Forbidden']]
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID'
        end
        delete ':id/pipelines/:pipeline_id' do
          authorize! :destroy_pipeline, pipeline

          destroy_conditionally!(pipeline) do
            ::Ci::DestroyPipelineService.new(user_project, current_user).execute(pipeline)
          end
        end

        desc 'Retry builds in the pipeline' do
          detail 'This feature was introduced in GitLab 8.11.'
          success Entities::Ci::Pipeline
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID'
        end
        post ':id/pipelines/:pipeline_id/retry' do
          authorize! :update_pipeline, pipeline

          pipeline.retry_failed(current_user)

          present pipeline, with: Entities::Ci::Pipeline
        end

        desc 'Cancel all builds in the pipeline' do
          detail 'This feature was introduced in GitLab 8.11.'
          success Entities::Ci::Pipeline
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID'
        end
        post ':id/pipelines/:pipeline_id/cancel' do
          authorize! :update_pipeline, pipeline

          pipeline.cancel_running

          status 200
          present pipeline.reset, with: Entities::Ci::Pipeline
        end
      end

      helpers do
        def pipeline
          strong_memoize(:pipeline) do
            user_project.all_pipelines.find(params[:pipeline_id])
          end
        end

        def latest_pipeline
          strong_memoize(:latest_pipeline) do
            user_project.latest_pipeline(params[:ref])
          end
        end
      end
    end
  end
end
