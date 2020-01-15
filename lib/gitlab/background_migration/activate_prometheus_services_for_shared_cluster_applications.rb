# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Create missing PrometheusServices records or sets active attribute to true
    # for all projects which belongs to cluster with Prometheus Application installed.
    class ActivatePrometheusServicesForSharedClusterApplications
      module Migratable
        # Migration model namespace isolated from application code.
        class PrometheusService < ActiveRecord::Base
          self.inheritance_column = :_type_disabled
          self.table_name = 'services'

          default_scope { where("services.type = 'PrometheusService'") }

          def self.for_project(project_id)
            new(
              project_id: project_id,
              active: true,
              properties: '{}',
              type: 'PrometheusService',
              template: false,
              push_events: true,
              issues_events: true,
              merge_requests_events: true,
              tag_push_events: true,
              note_events: true,
              category: 'monitoring',
              default: false,
              wiki_page_events: true,
              pipeline_events: true,
              confidential_issues_events: true,
              commit_events: true,
              job_events: true,
              confidential_note_events: true,
              deployment_events: false
            )
          end

          def managed?
            properties == '{}'
          end
        end
      end

      def perform(project_id)
        service = Migratable::PrometheusService.find_by(project_id: project_id) || Migratable::PrometheusService.for_project(project_id)
        service.update!(active: true) if service.managed?
      end
    end
  end
end
