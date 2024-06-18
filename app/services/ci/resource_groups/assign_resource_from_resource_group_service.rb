# frozen_string_literal: true

module Ci
  module ResourceGroups
    class AssignResourceFromResourceGroupService < ::BaseService
      RESPAWN_WAIT_TIME = 1.minute

      def execute(resource_group)
        release_resource_from_stale_jobs(resource_group)

        free_resources = resource_group.resources.free.count

        return if free_resources == 0

        enqueue_upcoming_processables(free_resources, resource_group)
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def enqueue_upcoming_processables(free_resources, resource_group)
        resource_group.upcoming_processables.take(free_resources).each do |upcoming|
          Gitlab::OptimisticLocking.retry_lock(upcoming, name: 'enqueue_waiting_for_resource') do |processable|
            if processable.has_outdated_deployment?
              processable.drop!(:failed_outdated_deployment_job)
            else
              processable.enqueue_waiting_for_resource
            end
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def release_resource_from_stale_jobs(resource_group)
        resource_group.resources.stale_processables.find_each do |processable|
          resource_group.release_resource_from(processable)
        end
      end
    end
  end
end
