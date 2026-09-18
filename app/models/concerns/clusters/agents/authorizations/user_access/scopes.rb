# frozen_string_literal: true

module Clusters
  module Agents
    module Authorizations
      module UserAccess
        module Scopes
          extend ActiveSupport::Concern

          included do
            scope :for_agent, ->(agent) { where(agent: agent) }
            scope :preloaded, -> { joins(agent: :project).preload(agent: :project) }

            # Administrators in admin mode are authorized for every agent, independent of their
            # memberships. They are treated as Owner, the same as `ProjectTeam#max_member_access`
            # and `Group#max_member_access` do.
            scope :for_admin, -> {
              select("#{table_name}.*, #{::Gitlab::Access::OWNER} AS access_level")
            }
          end
        end
      end
    end
  end
end
