# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountDistinctTopLevelGroupsWithContainerRegistryProtectionRulesMetric < DatabaseMetric
          operation :distinct_count, column: 'id'

          relation do
            project_ids_with_rules = ::ContainerRegistry::Protection::Rule.select(:project_id).distinct
            namespace_ids = ::Project.where(id: project_ids_with_rules).select(:namespace_id)

            ::Group.where(id: namespace_ids).roots
          end
        end
      end
    end
  end
end
