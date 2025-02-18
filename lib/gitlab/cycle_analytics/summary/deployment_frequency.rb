# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      class DeploymentFrequency < Base
        include SummaryHelper

        def initialize(deployments:, options:, project:)
          @deployments = deployments

          super(project: project, options: options)
        end

        def title
          _('Deployment frequency')
        end

        def value
          @value ||= frequency(@deployments, @options[:from], @options[:to] || Time.current)
        end

        def unit
          _('/day')
        end

        def links
          [
            { "name" => _('Deployment frequency'), "url" => Gitlab::Routing.url_helpers.charts_project_pipelines_path(project, chart: 'deployment-frequency'), "label" => s_('ValueStreamAnalytics|Dashboard') },
            { "name" => _('Deployment frequency'), "url" => Gitlab::Routing.url_helpers.help_page_path('user/analytics/_index.md', anchor: 'definitions'), "docs_link" => true, "label" => s_('ValueStreamAnalytics|Go to docs') }
          ]
        end
      end
    end
  end
end
