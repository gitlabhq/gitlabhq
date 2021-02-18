# frozen_string_literal: true

module Ci
  module ResourceGroups
    class AssignResourceFromResourceGroupService < ::BaseService
      # rubocop: disable CodeReuse/ActiveRecord
      def execute(resource_group)
        free_resources = resource_group.resources.free.count

        resource_group.processables.waiting_for_resource.take(free_resources).each do |processable|
          processable.enqueue_waiting_for_resource
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
