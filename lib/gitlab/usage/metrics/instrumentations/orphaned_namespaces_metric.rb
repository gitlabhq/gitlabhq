# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class OrphanedNamespacesMetric < GenericMetric
          value do
            ::Namespace
              .where.not(parent_id: nil)
              .where('NOT EXISTS(SELECT 1 FROM namespaces p WHERE p.id = namespaces.parent_id)')
              .exists?
          end
        end
      end
    end
  end
end
