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
          @project = Project.find_by_id(project_id)
          return unless @project

          @user = User.find_by_id(user_id)
          return unless @user

          @component_hashes = component_hashes
          @component_projects = load_component_projects

          track_all_components

          catalog_component_hashes = filter_catalog_component_hashes
          process_catalog_components(catalog_component_hashes)
        end

        private

        attr_reader :project, :user, :component_hashes, :component_projects

        def load_component_projects
          component_project_ids = component_hashes.pluck('project_id').uniq # rubocop:disable CodeReuse/ActiveRecord -- array pluck, not ActiveRecord
          component_projects = Project.id_in(component_project_ids).preload(:catalog_resource) # rubocop:disable CodeReuse/ActiveRecord -- worker needs to preload associations
          component_projects.index_by(&:id)
        end

        def filter_catalog_component_hashes
          component_hashes.select do |component_hash|
            component_projects[component_hash['project_id']]&.catalog_resource
          end
        end

        def track_all_components
          component_hashes.each do |component_hash|
            component_project = component_projects[component_hash['project_id']]

            next unless component_project

            track_all_components_event(component_hash, component_project)
          rescue StandardError => e
            Gitlab::ErrorTracking.track_exception(e)
          end
        end

        def process_catalog_components(catalog_component_hashes)
          grouped_hashes = group_by_project_and_sha(catalog_component_hashes)
          catalog_components = collect_catalog_components(grouped_hashes)

          return if catalog_components.empty?

          ::Ci::Components::Usages::CreateService.new(catalog_components, used_by_project: project).execute
        end

        def group_by_project_and_sha(catalog_component_hashes)
          catalog_component_hashes.group_by do |h|
            [h['project_id'], h['sha']]
          end
        end

        def collect_catalog_components(grouped_hashes)
          catalog_components = []

          grouped_hashes.each do |(project_id, sha), hashes|
            component_project = component_projects[project_id]
            component_names = hashes.pluck('name') # rubocop:disable CodeReuse/ActiveRecord -- array pluck, not ActiveRecord
            components = find_catalog_components_batch(component_project, sha, component_names)

            components.each do |component|
              track_catalog_component_event(component, component_project)

              catalog_components << { component: component, component_project: component_project }
            rescue StandardError => e
              Gitlab::ErrorTracking.track_exception(e)
            end
          end

          catalog_components
        end

        def find_catalog_components_batch(component_project, sha, component_names)
          components_project = ::Ci::Catalog::ComponentsProject.new(component_project, sha)

          components_project.find_catalog_components(component_names)
        end

        def track_all_components_event(component_hash, component_project)
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

        def track_catalog_component_event(component, component_project)
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
        end

        def component_type
          ::Ci::Catalog::Resources::Component.component_types[:template]
        end
      end
    end
  end
end
