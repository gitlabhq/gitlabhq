# frozen_string_literal: true

module API
  module Ci
    class Pipelines < ::API::Base
      include PaginationParams
      include APIGuard

      helpers ::API::Helpers::ProjectStatsRefreshConflictsHelpers
      helpers ::API::Ci::Helpers::PipelinesHelpers

      before { authenticate_non_get! }

      allow_access_with_scope :ai_workflows, if: ->(request) { request.get? || request.head? }

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

          pipelines = ::Ci::PipelinesFinder.new(user_project, current_user, params).execute
          pipelines = pipelines.preload_pipeline_metadata

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
          use :create_pipeline_params
        end
        post ':id/pipeline', urgency: :low, feature_category: :pipeline_composition do
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

          builds = builds.with_preloads.preload(:metadata, :runner_manager, :ci_stage) # rubocop:disable CodeReuse/ActiveRecord -- preload job.archived?

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
          # rubocop:disable CodeReuse/ActiveRecord -- Preload is only related to this endpoint
          bridges = bridges.with_preloads.preload(:ci_stage)
          # rubocop:enable CodeReuse/ActiveRecord

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
        get ':id/pipelines/:pipeline_id/variables', feature_category: :ci_variables, urgency: :low do
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

          cache_action_if(pipeline.has_test_reports?, [user_project, pipeline], expires_in: 2.minutes) do
            present pipeline.test_reports, with: TestReportEntity, details: true
          end
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

        desc 'Updates pipeline metadata' do
          detail 'This feature was introduced in GitLab 16.6'
          success status: 200, model: Entities::Ci::PipelineWithMetadata
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID', documentation: { example: 18 }
          requires :name, type: String, desc: 'The name of the pipeline', documentation: { example: 'Deployment to production' }
        end
        route_setting :authentication, job_token_allowed: true
        route_setting :authorization, job_token_policies: :admin_jobs
        put ':id/pipelines/:pipeline_id/metadata', urgency: :low, feature_category: :continuous_integration do
          authorize! :update_pipeline, pipeline

          response = ::Ci::Pipelines::UpdateMetadataService.new(pipeline, params.slice(:name)).execute

          if response.success?
            present response.payload, with: Entities::Ci::PipelineWithMetadata
          else
            render_api_error_with_reason!(response.reason, response.message, response.payload.join(', '))
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
          authorize! :cancel_pipeline, pipeline

          # TODO: inconsistent behavior: when pipeline is not cancelable we should return an error
          ::Ci::CancelPipelineService.new(pipeline: pipeline, current_user: current_user).execute

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

API::Ci::Pipelines.prepend_mod
