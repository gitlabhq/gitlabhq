# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      module Features
        # Feature-bounded entity for the hierarchy widget's `parent`, so the extra `namespace`
        # field below only inflates the hierarchy widget response, not every WorkItemReference
        # consumer. See https://docs.gitlab.com/development/api_styleguide/#high-impact-entities-and-feature-bounded-entities
        class HierarchyParent < WorkItemReference
          expose :namespace,
            using: ::API::Entities::NamespaceBasic,
            documentation: { type: 'Entities::NamespaceBasic' }
        end
      end
    end
  end
end
