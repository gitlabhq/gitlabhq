# frozen_string_literal: true

module Ci
  module ResourceGroups
    class AssignResourceFromResourceGroupService < ::BaseService
      # rubocop: disable CodeReuse/ActiveRecord
      def execute(resource_group)
        release_resource_from_stale_jobs(resource_group)

        free_resources = resource_group.resources.free.count

        resource_group.upcoming_processables.take(free_resources).each do |upcoming|
          Gitlab::OptimisticLocking.retry_lock(upcoming, name: 'enqueue_waiting_for_resource') do |processable|
            processable.enqueue_waiting_for_resource
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      def release_resource_from_stale_jobs(resource_group)
        resource_group.resources.stale_processables.find_each do |processable|
          resource_group.release_resource_from(processable)
        end
      end
    end
  end
end
