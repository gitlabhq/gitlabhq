# frozen_string_literal: true

module API
  module Ci
    class Pipelines < ::API::Base
      include ::API::Concerns::McpAccess
      include PaginationParams
      include APIGuard

      helpers ::API::Helpers::ProjectStatsRefreshConflictsHelpers
      helpers ::API::Ci::Helpers::PipelinesHelpers

      before { authenticate_non_get! }

      allow_mcp_access_read
      allow_mcp_access_create
      allow_mcp_access_delete
      allow_access_with_scope :ai_workflows, if: ->(request) { request.get? || request.head? }

      params do
        requires :id, type: String, desc: 'The project ID or URL-encoded path', documentation: { example: '11' }
      end
      resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'List all project pipelines' do
          detail 'Lists all pipelines in a project. By default, child pipelines are not included in the results. To ' \
            'return child pipelines, set `source` to `parent_pipeline`.'
          success status: 200, model: Entities::Ci::PipelineBasic
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' }
          ]
          is_array true
          tags ['pipelines']
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
          optional :created_before, type: DateTime, desc: 'Return pipelines created before the specified datetime. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ',
            documentation: { example: '2015-12-24T15:51:21.880Z' }
          optional :created_after, type: DateTime, desc: 'Return pipelines created after the specified datetime. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ',
            documentation: { example: '2015-12-24T15:51:21.880Z' }
          optional :order_by, type: String, values: ::Ci::PipelinesFinder::ALLOWED_INDEXED_COLUMNS, default: 'id',
            desc: 'Order pipelines',
            documentation: { example: 'status' }
          optional :sort,     type: String, values: %w[asc desc], default: 'desc',
            desc: 'Sort pipelines',
            documentation: { example: 'asc' }
          optional :source,   type: String, values: ::Ci::Pipeline.sources.keys,
            desc: 'The source of pipelines',
            documentation: { example: 'push' }
          optional :name,     types: String, desc: 'Filter pipelines by name',
            documentation: { example: 'Build pipeline' }
        end

        route_setting :mcp,
          tool_name: :list_pipelines,
          params: [:id, :ref, :page, :per_page],
          aggregators: [::Mcp::Tools::Pipelines::PipelineService],
          resource_name: "project"
        route_setting :authentication, job_token_allowed: true
        route_setting :authorization, job_token_policies: :read_pipelines,
          allow_public_access_for_enabled_project_features: [:repository, :builds],
          permissions: :read_pipeline, boundary_type: :project
        get ':id/pipelines', urgency: :low, feature_category: :continuous_integration do
          authorize! :read_pipeline, user_project
          authorize! :read_build, user_project

          pipelines = ::Ci::PipelinesFinder.new(user_project, current_user, params).execute
          pipelines = pipelines.preload_pipeline_metadata

          present paginate(pipelines), with: Entities::Ci::PipelineBasicWithMetadata, project: user_project
        end

        desc 'Create a pipeline' do
          detail 'Creates a pipeline in the specified project.'
          success status: 201, model: Entities::Ci::Pipeline
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags ['pipelines']
        end
        params do
          use :create_pipeline_params
        end

        route_setting :mcp,
          tool_name: :create_pipeline,
          params: [:id, :ref, :variables, :inputs],
          aggregators: [::Mcp::Tools::Pipelines::PipelineService],
          resource_name: "project"
        route_setting :authorization, permissions: :create_pipeline, boundary_type: :project
        route_setting :log_safety, { unsafe: %w[inputs] }
        post ':id/pipeline', urgency: :low, feature_category: :pipeline_composition do
          Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20711')

          authorize! :create_pipeline, user_project

          pipeline_params = declared_params(include_missing: false)
            .merge(variables_attributes: params[:variables])
            .except(:variables, :inputs)

          response = ::Ci::CreatePipelineService.new(user_project, current_user, pipeline_params)
            .execute(:api, ignore_skip_ci: true, save_on_errors: false, inputs: params[:inputs])
          new_pipeline = response.payload

          if response.success?
            present new_pipeline, with: Entities::Ci::Pipeline
          else
            render_validation_error!(new_pipeline)
          end
        end

        desc 'Retrieve the latest pipeline' do
          detail 'Retrieves the latest pipeline for the most recent commit on a specified ref in a project. If no ' \
            'pipeline exists for the commit, a `403` status code is returned. Use the `page` and `per_page` pagination ' \
            'parameters to control the pagination of results.'
          success status: 200, model: Entities::Ci::PipelineWithMetadata
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags ['pipelines']
        end
        params do
          optional :ref, type: String, desc: 'Branch ref of pipeline. Uses project default branch if not specified.',
            documentation: { example: 'develop' }
        end

        route_setting :authorization, permissions: :read_pipeline, boundary_type: :project
        get ':id/pipelines/latest', urgency: :low, feature_category: :continuous_integration do
          authorize! :read_pipeline, latest_pipeline

          present latest_pipeline, with: Entities::Ci::PipelineWithMetadata
        end

        desc 'Retrieve a pipeline' do
          detail 'Retrieves a specified pipeline from a project. You can also get a child pipeline.'
          success status: 200, model: Entities::Ci::PipelineWithMetadata
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags ['pipelines']
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID', documentation: { example: 18 }
        end

        route_setting :authentication, job_token_allowed: true
        route_setting :authorization, job_token_policies: :read_pipelines,
          allow_public_access_for_enabled_project_features: [:repository, :builds],
          permissions: :read_pipeline, boundary_type: :project
        get ':id/pipelines/:pipeline_id', urgency: :low, feature_category: :continuous_integration do
          authorize! :read_pipeline, pipeline

          present pipeline, with: Entities::Ci::PipelineWithMetadata
        end

        desc 'List all jobs by pipeline' do
          detail 'Lists all jobs for a specified pipeline.'
          success status: 200, model: Entities::Ci::Job
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          is_array true
          tags ['pipelines']
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID', documentation: { example: 18 }
          optional :include_retried, type: Boolean, default: false, desc: 'Includes retried jobs'
          use :optional_scope
          use :pagination
        end

        route_setting :mcp, tool_name: :get_pipeline_jobs, params: [:id, :pipeline_id, :per_page, :page], resource_name: "pipeline"
        route_setting :authentication, job_token_allowed: true
        route_setting :authorization, job_token_policies: :read_jobs,
          allow_public_access_for_enabled_project_features: [:repository, :builds],
          permissions: :read_pipeline_job, boundary_type: :project
        get ':id/pipelines/:pipeline_id/jobs', urgency: :low, feature_category: :continuous_integration do
          authorize!(:read_pipeline, user_project)

          pipeline = user_project.all_pipelines.find(params[:pipeline_id])

          builds = ::Ci::JobsFinder
            .new(current_user: current_user, pipeline: pipeline, params: params)
            .execute

          builds = builds.with_preloads.preload(:job_definition, :runner_manager, :ci_stage) # rubocop:disable CodeReuse/ActiveRecord -- preload job.archived?

          present paginate(builds), with: Entities::Ci::Job
        end

        desc 'List all bridge jobs by pipeline' do
          detail 'Deprecated in GitLab 19.2. Use trigger_jobs endpoint instead.'
          success status: 200, model: Entities::Ci::Bridge
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          is_array true
          tags ['pipelines']
          deprecated true
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID', documentation: { example: 18 }
          use :optional_scope
          use :pagination
        end

        route_setting :authentication, job_token_allowed: true
        route_setting :authorization, job_token_policies: :read_pipelines,
          allow_public_access_for_enabled_project_features: [:repository, :builds],
          permissions: :read_pipeline_bridge, boundary_type: :project
        get ':id/pipelines/:pipeline_id/bridges',
          urgency: :low, feature_category: :pipeline_composition do
          present_pipeline_trigger_jobs
        end

        desc 'List all trigger jobs by pipeline' do
          detail 'Lists all trigger jobs for a specified pipeline.'
          success status: 200, model: Entities::Ci::Bridge
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          is_array true
          tags ['pipelines']
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID', documentation: { example: 18 }
          use :optional_scope
          use :pagination
        end

        route_setting :authentication, job_token_allowed: true
        route_setting :authorization, job_token_policies: :read_pipelines,
          allow_public_access_for_enabled_project_features: [:repository, :builds],
          permissions: :read_pipeline_bridge, boundary_type: :project
        get ':id/pipelines/:pipeline_id/trigger_jobs',
          urgency: :low, feature_category: :pipeline_composition do
          present_pipeline_trigger_jobs
        end

        desc 'List all pipeline variables' do
          detail 'Lists all pipeline variables for a specified pipeline. Use the `page` and `per_page` pagination ' \
            'parameters to control the pagination of results.'
          success status: 200, model: Entities::Ci::Variable
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          is_array true
          tags ['pipelines']
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID', documentation: { example: 18 }
        end

        route_setting :authorization, permissions: :read_pipeline_variable, boundary_type: :project
        get ':id/pipelines/:pipeline_id/variables', feature_category: :pipeline_composition, urgency: :low do
          authorize! :read_pipeline_variable, pipeline

          present pipeline.variables, with: Entities::Ci::Variable
        end

        desc 'Retrieve a test report for a pipeline' do
          detail 'Retrieves a test report for a pipeline.'
          success status: 200, model: TestReportEntity
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags ['pipelines']
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID', documentation: { example: 18 }
        end

        route_setting :authorization, permissions: :read_pipeline_test_report, boundary_type: :project
        get ':id/pipelines/:pipeline_id/test_report', feature_category: :code_testing, urgency: :low do
          authorize! :read_build, pipeline

          cache_action_if(pipeline.has_test_reports?, [user_project, pipeline], expires_in: 2.minutes) do
            present pipeline.test_reports, with: TestReportEntity, details: true
          end
        end

        desc 'Retrieve a test report summary for a pipeline' do
          detail 'Retrieves a test report summary for a pipeline.'
          success status: 200, model: TestReportSummaryEntity
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags ['pipelines']
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID', documentation: { example: 18 }
        end

        route_setting :authorization, permissions: :read_pipeline_test_report_summary, boundary_type: :project
        get ':id/pipelines/:pipeline_id/test_report_summary', feature_category: :code_testing do
          authorize! :read_build, pipeline

          present pipeline.test_report_summary, with: TestReportSummaryEntity
        end

        desc 'Delete a pipeline' do
          detail 'Deletes a specified pipeline for a project.'
          success code: 204, message: 'Pipeline was deleted'
          failure [[403, 'Forbidden']]
          tags ['pipelines']
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID', documentation: { example: 18 }
        end

        route_setting :mcp,
          tool_name: :delete_pipeline,
          params: [:id, :pipeline_id],
          aggregators: [::Mcp::Tools::Pipelines::PipelineService],
          resource_name: "pipeline"
        route_setting :authorization, permissions: :delete_pipeline, boundary_type: :project
        delete ':id/pipelines/:pipeline_id', urgency: :low, feature_category: :continuous_integration do
          authorize! :destroy_pipeline, pipeline

          reject_if_build_artifacts_size_refreshing!(pipeline.project)

          destroy_conditionally!(pipeline) do
            ::Ci::DestroyPipelineService.new(user_project, current_user).execute(pipeline)
          end
        end

        desc 'Update pipeline metadata' do
          detail 'Updates pipeline metadata. The metadata contains the name of the pipeline. This feature was ' \
            'introduced in GitLab 16.6.'
          success status: 200, model: Entities::Ci::PipelineWithMetadata
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags ['pipelines']
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID', documentation: { example: 18 }
          requires :name, type: String, desc: 'The name of the pipeline', documentation: { example: 'Deployment to production' }
        end
        route_setting :mcp,
          tool_name: :update_pipeline,
          params: [:id, :pipeline_id, :name],
          aggregators: [::Mcp::Tools::Pipelines::PipelineService],
          resource_name: "pipeline"
        route_setting :authentication, job_token_allowed: true
        route_setting :authorization, permissions: :update_pipeline_metadata, boundary_type: :project,
          job_token_policies: :admin_pipelines
        put ':id/pipelines/:pipeline_id/metadata', urgency: :low, feature_category: :continuous_integration do
          authorize! :update_pipeline, pipeline

          response = ::Ci::Pipelines::UpdateMetadataService
            .new(pipeline, current_user: current_user, params: params.slice(:name))
            .execute

          if response.success?
            present response.payload, with: Entities::Ci::PipelineWithMetadata
          else
            render_api_error_with_reason!(response.reason, response.message, response.payload.join(', '))
          end
        end

        desc 'Retry jobs in a pipeline' do
          detail 'Retries failed or canceled jobs in a pipeline. If there are no failed or canceled jobs in the ' \
            'pipeline, calling this endpoint has no effect.'
          success status: 201, model: Entities::Ci::Pipeline
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags ['pipelines']
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID', documentation: { example: 18 }
        end

        route_setting :mcp,
          tool_name: :retry_pipeline,
          params: [:id, :pipeline_id],
          aggregators: [::Mcp::Tools::Pipelines::PipelineService],
          resource_name: "pipeline"
        route_setting :authorization, permissions: :retry_pipeline, boundary_type: :project
        post ':id/pipelines/:pipeline_id/retry', urgency: :low, feature_category: :continuous_integration do
          authorize! :update_pipeline, pipeline

          response = pipeline.retry_failed(current_user)

          if response.success?
            present pipeline, with: Entities::Ci::Pipeline
          else
            render_api_error!(response.errors.join(', '), response.http_status)
          end
        end

        desc 'Cancel all jobs for a pipeline' do
          detail 'Cancels all jobs in a specified pipeline.'
          success status: 200, model: Entities::Ci::Pipeline
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags ['pipelines']
        end
        params do
          requires :pipeline_id, type: Integer, desc: 'The pipeline ID', documentation: { example: 18 }
        end

        route_setting :mcp,
          tool_name: :cancel_pipeline,
          params: [:id, :pipeline_id],
          aggregators: [::Mcp::Tools::Pipelines::PipelineService],
          resource_name: "pipeline"
        route_setting :authorization, permissions: :cancel_pipeline, boundary_type: :project
        post ':id/pipelines/:pipeline_id/cancel', urgency: :low, feature_category: :continuous_integration do
          authorize! :cancel_pipeline, pipeline

          # TODO: inconsistent behavior: when pipeline is not cancelable we should return an error
          # Set to be fixed on V5 to avoid breaking changes: https://gitlab.com/gitlab-org/gitlab/-/issues/519143
          ::Ci::CancelPipelineService.new(pipeline: pipeline, current_user: current_user).execute

          status 200
          present pipeline.reset, with: Entities::Ci::Pipeline
        end
      end

      helpers do
        def present_pipeline_trigger_jobs
          authorize!(:read_build, user_project)

          bridges = ::Ci::JobsFinder
            .new(current_user: current_user, pipeline: pipeline, params: params, type: ::Ci::Bridge)
            .execute
          # rubocop:disable CodeReuse/ActiveRecord -- Preload is only related to this endpoint
          bridges = bridges.with_preloads.preload(:ci_stage)
          # rubocop:enable CodeReuse/ActiveRecord

          present paginate(bridges), with: Entities::Ci::Bridge
        end

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
