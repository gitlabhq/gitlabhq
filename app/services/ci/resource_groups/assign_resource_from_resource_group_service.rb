# frozen_string_literal: true

module Ci
  module ResourceGroups
    class AssignResourceFromResourceGroupService < ::BaseService
      # rubocop: disable CodeReuse/ActiveRecord
      def execute(resource_group)
        free_resources = resource_group.resources.free.count

        resource_group.builds.waiting_for_resource.take(free_resources).each do |build|
          build.enqueue_waiting_for_resource
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
