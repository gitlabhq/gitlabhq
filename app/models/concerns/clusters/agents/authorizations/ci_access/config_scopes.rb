# frozen_string_literal: true

module Clusters
  module Agents
    module Authorizations
      module CiAccess
        module ConfigScopes
          extend ActiveSupport::Concern

          included do
            scope :with_available_ci_access_fields, ->(project) {
              where("config->'access_as' IS NULL")
                .or(where("config->'access_as' = '{}'"))
                .or(where("config->'access_as' ?| array[:fields]", fields: available_ci_access_fields(project)))
            }
          end

          class_methods do
            def available_ci_access_fields(_project)
              %w[agent]
            end
          end
        end
      end
    end
  end
end

Clusters::Agents::Authorizations::CiAccess::ConfigScopes.prepend_mod
