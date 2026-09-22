# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      module Terraform
        # Loads the versions of every Terraform state in a query with one
        # JOIN LATERAL, so a page of states does not run a query per state.
        class StateVersionsLoader < LazyRelationLoader
          self.model = ::Terraform::State
          self.association = :versions

          def relation(**)
            base_relation.ordered_by_version_desc
          end
        end
      end
    end
  end
end
