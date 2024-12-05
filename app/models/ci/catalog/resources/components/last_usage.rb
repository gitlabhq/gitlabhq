# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      module Components
        class LastUsage < ::ApplicationRecord
          include EachBatch

          self.table_name = 'catalog_resource_component_last_usages'
          self.primary_key = :id

          scope :older_than_30_days, -> { where(last_used_date: ...30.days.ago.to_date) }

          belongs_to :component, class_name: 'Ci::Catalog::Resources::Component', inverse_of: :last_usages
          belongs_to :catalog_resource, class_name: 'Ci::Catalog::Resource', inverse_of: :component_last_usages
          belongs_to :component_project, class_name: 'Project', inverse_of: :ci_component_last_usages

          validates :component, :catalog_resource, :component_project, :used_by_project_id, presence: true

          validates :last_used_date, uniqueness: { scope: [:component_id, :used_by_project_id] }, presence: true

          def self.get_usage_for(component, used_by_project)
            Ci::Catalog::Resources::Components::LastUsage.find_or_initialize_by(
              component: component,
              catalog_resource: component.catalog_resource,
              component_project: component.project,
              used_by_project_id: used_by_project.id
            )
          end

          def self.by_project_ids(project_ids)
            where(used_by_project_id: project_ids)
              .group_by(&:used_by_project_id)
          end
        end
      end
    end
  end
end
