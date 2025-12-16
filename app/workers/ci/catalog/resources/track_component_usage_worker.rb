# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      class TrackComponentUsageWorker
        include ApplicationWorker
        include PipelineQueue

        data_consistency :delayed
        feature_category :pipeline_composition
        urgency :throttled
        idempotent!

        def perform(project_id, user_id, component_hashes)
          project = Project.find_by_id(project_id)
          return unless project

          user = User.find_by_id(user_id)
          return unless user

          component_hashes.each do |component_hash|
            process_component(component_hash, project, user)
          rescue StandardError => e
            Gitlab::ErrorTracking.track_exception(e)
          end
        end

        private

        def process_component(component_hash, project, user)
          component_project = Project.find_by_id(component_hash['project_id'])
          return unless component_project

          track_all_components_event(component_hash, component_project, project, user)

          component = ::Ci::Catalog::ComponentsProject.new(component_project, component_hash['sha'])
            .find_catalog_component(component_hash['name'])
          return unless component

          track_catalog_component_event(component, component_project, project, user)
        end

        def track_all_components_event(component_hash, component_project, project, user)
          Gitlab::InternalEvents.track_event(
            'ci_component_included',
            namespace: project.namespace,
            project: project,
            user: user,
            additional_properties: {
              label: "#{component_project.full_path}/#{component_hash['name']}",
              value: component_type,
              property: component_hash['sha']
            }
          )
        end

        def track_catalog_component_event(component, component_project, project, user)
          Gitlab::InternalEvents.track_event(
            'ci_catalog_component_included',
            namespace: project.namespace,
            project: project,
            user: user,
            additional_properties: {
              label: "#{component_project.full_path}/#{component.name}",
              value: component.component_type_before_type_cast,
              property: component.version.name
            }
          )

          ::Ci::Components::Usages::CreateService.new(component, used_by_project: project).execute
        end

        def component_type
          ::Ci::Catalog::Resources::Component.component_types[:template]
        end
      end
    end
  end
end
