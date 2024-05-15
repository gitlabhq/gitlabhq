# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      module Components
        # This model is used to track when a project includes a catalog component in
        # a pipeline with the keyword `include:component`. Usage data is recorded
        # during pipeline creation in Gitlab::Ci::Pipeline::Chain::ComponentUsage.
        # The column `used_by_project_id` does not have an FK constraint because
        # we want to preserve historical usage data.
        class Usage < ::ApplicationRecord
          include PartitionedTable
          include EachBatch

          self.table_name = 'p_catalog_resource_component_usages'
          self.primary_key = :id

          # TODO: Retention period to be shortened in https://gitlab.com/gitlab-org/gitlab/-/issues/443681
          partitioned_by :used_date, strategy: :monthly, retain_for: 12.months

          belongs_to :component, class_name: 'Ci::Catalog::Resources::Component', inverse_of: :usages
          belongs_to :catalog_resource, class_name: 'Ci::Catalog::Resource', inverse_of: :component_usages
          belongs_to :project, inverse_of: :ci_component_usages

          validates :component, :catalog_resource, :project, :used_by_project_id, presence: true
          validates :used_date, uniqueness: { scope: [:component_id, :used_by_project_id] }

          before_validation :set_used_date, unless: :used_date?

          private

          def set_used_date
            self.used_date = Date.today
          end
        end
      end
    end
  end
end
