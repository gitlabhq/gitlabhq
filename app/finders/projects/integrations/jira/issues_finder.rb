# frozen_string_literal: true

module Projects
  module Integrations
    module Jira
      IntegrationError = Class.new(StandardError)
      RequestError = Class.new(StandardError)

      class IssuesFinder
        attr_reader :issues, :total_count, :per_page

        class << self
          def valid_params
            @valid_params ||= %i[page per_page search state status author_username assignee_username]
            # to permit array params you need to init them to an empty array
            @valid_params << { labels: [] }
          end
        end

        def initialize(project, params = {})
          @project = project
          @jira_service = project.jira_service
          @params = params.merge(map_sort_values(params[:sort]))
          set_pagination
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
          response = ::Jira::Requests::Issues::ListService
                       .new(jira_service, { jql: jql, page: page, per_page: per_page })
                       .execute

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
          when 'created_date', 'created_desc'
            { sort: 'created', sort_direction: 'DESC' }
          when 'created_asc'
            { sort: 'created', sort_direction: 'ASC' }
          when 'updated_desc'
            { sort: 'updated', sort_direction: 'DESC' }
          when 'updated_asc'
            { sort: 'updated', sort_direction: 'ASC' }
          else
            { sort: ::Jira::JqlBuilderService::DEFAULT_SORT, sort_direction: ::Jira::JqlBuilderService::DEFAULT_SORT_DIRECTION }
          end
        end

        def set_pagination
          @page = (params[:page].presence || 1).to_i
          @per_page = (params[:per_page].presence || ::Jira::Requests::Issues::ListService::PER_PAGE).to_i
        end
      end
    end
  end
end
