# frozen_string_literal: true

module API
  module Ci
    class Pipelines < ::API::Base
      include PaginationParams

      helpers ::API::Helpers::ProjectStatsRefreshConflictsHelpers

      before { authenticate_non_get! }

      params do
        requires :id, type: String, desc: 'The project ID or URL-encoded path', documentation: { example: 11 }
      end
      resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Get all Pipelines of the project' do
          detail 'This feature was introduced in GitLab 8.11.'
          success status: 200, model: Entities::Ci::PipelineBasic
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' }
          ]
          is_array true
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
                                          },
                             documentation: { example: %w[pending running] }
          end
        end

        params do
          use :pagination
          optional :scope,    type: String, values: %w[running pending finished branches tags],
                              desc: 'The scope of pipelines',
                              documentation: { example: 'pending' }
          optional :status,   type: String, values: ::Ci::HasStatus::AVAILABLE_STATUSES,
                              desc: 'The status of pipelines',
                              documentation: { example: 'pending' }
          optional :ref,      type: String, desc: 'The ref of pipelines',
                              documentation: { example: 'develop' }
          optional :sha,      type: String, desc: 'The sha of pipelines',
                              documentation: { example: 'a91957a858320c0e17f3a0eca7cfacbff50ea29a' }
          optional :yaml_errors, type: Boolean, desc: 'Returns pipelines with invalid configurations',
                                 documentation: { example: false }
          optional :username, type: String, desc: 'The username of the user who triggered pipelines',
                              documentation: { example: 'root' }
          optional :updated_before, type: DateTime, desc: 'Return pipelines updated before the specified datetime. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ',
                                    documentation: { example: '2015-12-24T15:51:21.880Z' }
          optional :updated_after, type: DateTime, desc: 'Return pipelines updated after the specified datetime. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ',
                                   documentation: { example: '2015-12-24T15:51:21.880Z' }
          optional :order_by, type: String, values: ::Ci::PipelinesFinder::ALLOWED_INDEXED_COLUMNS, default: 'id',
                              desc: 'Order pipelines',
                              documentation: { example: 'status' }
          optional :sort,     type: String, values: %w[asc desc], default: 'desc',
                              desc: 'Sort pipelines',
                              documentation: { example: 'asc' }
          optional :source,   type: String, values: ::Ci::Pipeline.sources.keys,
                              documentation: { example: 'push' }
          optional :name,     types: String, desc: 'Filter pipelines by name',
                              documentation: { example: 'Build pipeline' }
        end
        get ':id/pipelines', urgency: :low, feature_category: :continuous_integration do
          authorize! :read_pipeline, user_project
          authorize! :read_build, user_project

          params.delete(:name) unless ::Feature.enabled?(:pipeline_name_in_api, user_project)

          pipelines = ::Ci::PipelinesFinder.new(user_project, current_user, params).execute
          pipelines = pipelines.preload_pipeline_metadata if ::Feature.enabled?(:pipeline_name_in_api, user_project)

          present paginate(pipelines), with: Entities::Ci::PipelineBasicWithMetadata, project: user_project
        end

        desc 'Create a new pipeline' do
          detail 'This feature was introduced in GitLab 8.14'
          success status: 201, model: Entities::Ci::Pipeline
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :ref, type: String, desc: 'Reference',
                         documentation: { example: 'develop' }
          optional :variables, type: Array, desc: 'Array of variables available in the pipeline' do
            optional :key, type: String, desc: 'The key of the variable', documentation: { example: 'UPLOAD_TO_S3' }
            optional :value, type: String, desc: 'The value of the variable', documentation: { example: 'true' }
            optional :variable_type, type: String, values: ::Ci::PipelineVariable.variable_types.keys, default: 'env_var', desc: 'The type of variable, must be one of env_var or file. Defaults to env_var'
          end
        end
        post ':id/pipeline', urgency: :low, feature_category: :continuous_integration do
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

        desc 'Gets the latest pipeline for the project branch' do
          detail 'This feature was introduced in GitLab 12.3'
          success status: 200, model: Entities::Ci::PipelineWithMetadata
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          optional :ref, type: String, desc: 'Branch ref of pipeline. Uses project default branch if not specified.',
                         documentation: { example: 'develop' }
        end
        get ':id/pipelines/latest', urgency: :low, feature_category: :continuous_integration do
          authorize! :read_pipeline, latest_pipeline

          present latest_pipeline, with: Entities::Ci::PipelineWithMetadata
        end

        desc 'Gets a specific pipeline for the project' do
          detail 'This feature was introduced in GitLab 8.11'
          success status: 200, model: Entities::Ci::PipelineWithMetadata
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID', documentation: { example: 18 }
        end
        get ':id/pipelines/:pipeline_id', urgency: :low, feature_category: :continuous_integration do
          authorize! :read_pipeline, pipeline

          present pipeline, with: Entities::Ci::PipelineWithMetadata
        end

        desc 'Get pipeline jobs' do
          success status: 200, model: Entities::Ci::Job
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          is_array true
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID', documentation: { example: 18 }
          optional :include_retried, type: Boolean, default: false, desc: 'Includes retried jobs'
          use :optional_scope
          use :pagination
        end

        get ':id/pipelines/:pipeline_id/jobs', urgency: :low, feature_category: :continuous_integration do
          authorize!(:read_pipeline, user_project)

          pipeline = user_project.all_pipelines.find(params[:pipeline_id])

          builds = ::Ci::JobsFinder
            .new(current_user: current_user, pipeline: pipeline, params: params)
            .execute

          builds = builds.with_preloads

          present paginate(builds), with: Entities::Ci::Job
        end

        desc 'Get pipeline bridge jobs' do
          success status: 200, model: Entities::Ci::Bridge
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          is_array true
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID', documentation: { example: 18 }
          use :optional_scope
          use :pagination
        end

        get ':id/pipelines/:pipeline_id/bridges', urgency: :low, feature_category: :pipeline_composition do
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
          success status: 200, model: Entities::Ci::Variable
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          is_array true
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID', documentation: { example: 18 }
        end
        get ':id/pipelines/:pipeline_id/variables', feature_category: :secrets_management, urgency: :low do
          authorize! :read_pipeline_variable, pipeline

          present pipeline.variables, with: Entities::Ci::Variable
        end

        desc 'Gets the test report for a given pipeline' do
          detail 'This feature was introduced in GitLab 13.0.'
          success status: 200, model: TestReportEntity
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID', documentation: { example: 18 }
        end
        get ':id/pipelines/:pipeline_id/test_report', feature_category: :code_testing, urgency: :low do
          authorize! :read_build, pipeline

          present pipeline.test_reports, with: TestReportEntity, details: true
        end

        desc 'Gets the test report summary for a given pipeline' do
          detail 'This feature was introduced in GitLab 14.2'
          success status: 200, model: TestReportSummaryEntity
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID', documentation: { example: 18 }
        end
        get ':id/pipelines/:pipeline_id/test_report_summary', feature_category: :code_testing do
          authorize! :read_build, pipeline

          present pipeline.test_report_summary, with: TestReportSummaryEntity
        end

        desc 'Deletes a pipeline' do
          detail 'This feature was introduced in GitLab 11.6'
          http_codes [[204, 'Pipeline was deleted'], [403, 'Forbidden']]
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID', documentation: { example: 18 }
        end
        delete ':id/pipelines/:pipeline_id', urgency: :low, feature_category: :continuous_integration do
          authorize! :destroy_pipeline, pipeline

          reject_if_build_artifacts_size_refreshing!(pipeline.project)

          destroy_conditionally!(pipeline) do
            ::Ci::DestroyPipelineService.new(user_project, current_user).execute(pipeline)
          end
        end

        desc 'Retry builds in the pipeline' do
          detail 'This feature was introduced in GitLab 8.11.'
          success status: 201, model: Entities::Ci::Pipeline
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID', documentation: { example: 18 }
        end
        post ':id/pipelines/:pipeline_id/retry', urgency: :low, feature_category: :continuous_integration do
          authorize! :update_pipeline, pipeline

          response = pipeline.retry_failed(current_user)

          if response.success?
            present pipeline, with: Entities::Ci::Pipeline
          else
            render_api_error!(response.errors.join(', '), response.http_status)
          end
        end

        desc 'Cancel all builds in the pipeline' do
          detail 'This feature was introduced in GitLab 8.11.'
          success status: 200, model: Entities::Ci::Pipeline
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID', documentation: { example: 18 }
        end
        post ':id/pipelines/:pipeline_id/cancel', urgency: :low, feature_category: :continuous_integration do
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
