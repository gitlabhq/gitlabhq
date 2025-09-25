# frozen_string_literal: true

module API
  module Mcp
    module Handlers
      # See: https://modelcontextprotocol.io/specification/2025-06-18/schema#listtoolsrequest
      class ListToolsRequest < Base
        # TODO: Autogenerate MCP Tools based on OpenAPI specification
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/554946
        API_TOOLS = {
          'get_issue' => ::Mcp::Tools::GetIssueService,
          'create_issue' => ::Mcp::Tools::CreateIssueService,
          'get_merge_request' => ::Mcp::Tools::GetMergeRequestService,
          'get_merge_request_changes' => ::Mcp::Tools::GetMergeRequestChangesService,
          'get_merge_request_commits' => ::Mcp::Tools::GetMergeRequestCommitsService,
          'get_merge_request_pipelines' => ::Mcp::Tools::GetMergeRequestPipelinesService,
          'get_pipeline_jobs' => ::Mcp::Tools::GetPipelineJobsService
        }.freeze
        CUSTOM_TOOLS = {
          'get_mcp_server_version' => ::Mcp::Tools::GetServerVersionService
        }.freeze
        TOOLS = CUSTOM_TOOLS.merge(API_TOOLS)

        def invoke
          {
            tools: tools
          }
        end

        private

        def tools
          TOOLS.map do |tool_name, tool_klass|
            tool_klass.new(name: tool_name).to_h
          end
        end
      end
    end
  end
end
