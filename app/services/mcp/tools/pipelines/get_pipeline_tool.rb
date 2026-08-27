# frozen_string_literal: true

module Mcp
  module Tools
    module Pipelines
      class GetPipelineTool < Mcp::Tools::Base::GraphqlTool
        include Mcp::Tools::Concerns::ResourceFinder
        include Mcp::Tools::Concerns::CursorPagination
        include Gitlab::Utils::StrongMemoize

        FACETS = {
          includeJobs: 'jobs',
          includeDownstreamPipelines: 'downstream_pipelines',
          includeBridgeJobs: 'bridge_jobs'
        }.freeze

        register_version VERSIONS[:v0_1_0], {
          operation_name: 'project',
          graphql_operation: load_graphql('pipelines/get_pipeline.query.graphql')
        }

        def execute
          return resource_not_found_error('Project') unless project

          super
        end

        def build_variables
          facets = Array(params[:include]).map(&:to_s)

          FACETS.transform_values { |facet| facets.include?(facet) }.merge(
            fullPath: project.full_path,
            pipelineId: "gid://gitlab/Ci::Pipeline/#{params[:pipeline_id]}",
            jobStatuses: params[:job_status].present? ? [params[:job_status].upcase] : nil,
            first: paginated_first,
            after: params[:after]
          ).compact
        end

        protected

        def build_variables_v0_1_0
          build_variables
        end

        private

        def project
          find_project(params[:id])
        end
        strong_memoize_attr :project

        def process_result(result)
          missing = missing_resource(result)
          return resource_not_found_error(missing) if missing

          processed_result = super
          return processed_result if processed_result[:isError]

          data = pipeline_data(processed_result[:structuredContent]['pipeline'])
          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(data) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, data)
        end

        def missing_resource(result)
          return if result['errors'].present?

          project = result.dig('data', 'project')
          return 'Project' if project.nil?

          'Pipeline' if project['pipeline'].nil?
        end

        def resource_not_found_error(resource)
          ::Mcp::Tools::Base::Response.error(
            "#{resource} not found or inaccessible"
          )
        end

        def pipeline_data(pipeline)
          data = {
            id: unwrap_id(pipeline['id']),
            status: pipeline['status'].downcase,
            ref: pipeline['ref'],
            sha: pipeline['sha'],
            source: pipeline['source'],
            web_url: web_url(pipeline['path'])
          }

          # Downstream pipelines can live in another project, so callers need the path to chain a follow-up call.
          data[:project_full_path] = pipeline.dig('project', 'fullPath') if pipeline['project']

          if pipeline['jobs']
            data[:jobs] = pipeline['jobs']['nodes'].map { |job| job_data(job) }
            data[:page_info] = page_info(pipeline['jobs'])
          end

          if pipeline['downstream']
            data[:downstream_pipelines] = pipeline['downstream']['nodes'].map { |downstream| pipeline_data(downstream) }
            data[:page_info] = page_info(pipeline['downstream'])
          end

          if pipeline['bridgeJobs']
            data[:bridge_jobs] = pipeline['bridgeJobs']['nodes'].map { |bridge| bridge_data(bridge) }
            data[:page_info] = page_info(pipeline['bridgeJobs'])
          end

          data
        end

        def page_info(connection)
          {
            has_next_page: connection.dig('pageInfo', 'hasNextPage'),
            end_cursor: connection.dig('pageInfo', 'endCursor')
          }
        end

        def job_data(job)
          {
            id: unwrap_id(job['id']),
            name: job['name'],
            status: job['status'].downcase,
            stage: job.dig('stage', 'name'),
            allow_failure: job['allowFailure'],
            web_url: web_url(job['webPath'])
          }
        end

        def bridge_data(bridge)
          downstream_pipeline = bridge['downstreamPipeline']

          {
            id: unwrap_id(bridge['id']),
            name: bridge['name'],
            status: bridge['status'].downcase,
            downstream_pipeline: downstream_pipeline ? pipeline_data(downstream_pipeline) : nil
          }
        end

        def unwrap_id(gid)
          ::GlobalID.parse(gid).model_id.to_i
        end

        def web_url(path)
          return unless path

          ::Gitlab::Utils.append_path(::Gitlab.config.gitlab.url, path)
        end
      end
    end
  end
end
