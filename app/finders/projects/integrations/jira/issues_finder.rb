# frozen_string_literal: true

module Projects
  module Integrations
    module Jira
      IntegrationError = Class.new(StandardError)
      RequestError = Class.new(StandardError)

      class IssuesFinder
        attr_reader :issues, :total_count

        def initialize(project, params = {})
          @project = project
          @jira_service = project.jira_service
          @page = params[:page].presence || 1
          @params = params
          @params = @params.reverse_merge(map_sort_values(@params.delete(:sort)))
        end

        def execute
          return [] unless Feature.enabled?(:jira_integration, project)

          raise IntegrationError, _('Jira service not configured.') unless jira_service&.active?

          project_key = jira_service.project_key
          raise IntegrationError, _('Jira project key is not configured') if project_key.blank?

          fetch_issues(project_key)
        end

        private

        attr_reader :project, :jira_service, :page, :params

        # rubocop: disable CodeReuse/ServiceClass
        def fetch_issues(project_key)
          jql = ::Jira::JqlBuilderService.new(project_key, params).execute
          response = ::Jira::Requests::Issues::ListService.new(jira_service, { jql: jql, page: page }).execute

          if response.success?
            @total_count = response.payload[:total_count]
            @issues = response.payload[:issues]
          else
            raise RequestError, response.message
          end
        end
        # rubocop: enable CodeReuse/ServiceClass

        def map_sort_values(sort)
          case sort
          when 'created_date'
            { sort: 'created', sort_direction: 'DESC' }
          else
            { sort: ::Jira::JqlBuilderService::DEFAULT_SORT, sort_direction: ::Jira::JqlBuilderService::DEFAULT_SORT_DIRECTION }
          end
        end
      end
    end
  end
end
