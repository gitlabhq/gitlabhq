# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      module Components
        class LastUsage < ::ApplicationRecord
          include EachBatch

          self.table_name = 'catalog_resource_component_last_usages'
          self.primary_key = :id

          belongs_to :component, class_name: 'Ci::Catalog::Resources::Component', inverse_of: :last_usages
          belongs_to :catalog_resource, class_name: 'Ci::Catalog::Resource', inverse_of: :component_last_usages
          belongs_to :component_project, class_name: 'Project', inverse_of: :ci_component_last_usages

          validates :component, :catalog_resource, :component_project, :used_by_project_id, presence: true

          validates :last_used_date, uniqueness: { scope: [:component_id, :used_by_project_id] }, presence: true
        end
      end
    end
  end
end
