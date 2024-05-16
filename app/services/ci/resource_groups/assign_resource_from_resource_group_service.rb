# frozen_string_literal: true

module Ci
  module ResourceGroups
    class AssignResourceFromResourceGroupService < ::BaseService
      RESPAWN_WAIT_TIME = 1.minute

      def execute(resource_group)
        release_resource_from_stale_jobs(resource_group)

        free_resources = resource_group.resources.free.count

        if free_resources == 0
          if resource_group.waiting_processables.any?
            # if the resource group is still 'tied up' in other processables,
            #   and there are more upcoming processables
            # kick off the worker again for the current resource group
            respawn_assign_resource_worker(resource_group)
          end

          return
        end

        enqueue_upcoming_processables(free_resources, resource_group)
      end

      private

      def respawn_assign_resource_worker(resource_group)
        return if Feature.disabled?(:respawn_assign_resource_worker, project, type: :gitlab_com_derisk)

        assign_resource_from_resource_group(resource_group)
      end

      def assign_resource_from_resource_group(resource_group)
        if Feature.enabled?(:assign_resource_worker_deduplicate_until_executing, project)
          Ci::ResourceGroups::AssignResourceFromResourceGroupWorkerV2.perform_in(RESPAWN_WAIT_TIME, resource_group.id)
        else
          Ci::ResourceGroups::AssignResourceFromResourceGroupWorker.perform_in(RESPAWN_WAIT_TIME, resource_group.id)
        end
      end

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
