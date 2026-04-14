# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Group
      class MaxIidsSaver < BaseMaxIidsSaver
        RESOURCE_QUERIES = {
          group_milestones: ->(group) { group.milestones.maximum(:iid) }
        }.freeze

        def self.resource_queries
          RESOURCE_QUERIES
        end

        def initialize(group:, shared:)
          super(exportable: group, shared: shared)
        end
      end
    end
  end
end

Gitlab::ImportExport::Group::MaxIidsSaver.prepend_mod
