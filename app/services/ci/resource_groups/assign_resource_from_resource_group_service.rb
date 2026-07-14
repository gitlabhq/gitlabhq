# frozen_string_literal: true

module Ci
  module ResourceGroups
    class AssignResourceFromResourceGroupService < ::BaseService
      include Gitlab::InternalEventsTracking

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
        upcoming_processables = resource_group.upcoming_processables
        preload_enabled = resource_group_assignment_preloads_enabled?(resource_group)

        if preload_enabled
          upcoming_processables = upcoming_processables
            .preload(:user, :job_environment, :job_definition, deployment: :environment, project: :ci_cd_settings)
        end

        upcoming_processables = upcoming_processables.take(free_resources)

        preload_environment_last_deployments(upcoming_processables) if preload_enabled

        upcoming_processables.each do |upcoming|
          enqueued = enqueue_upcoming(upcoming)

          next unless enqueued

          track_internal_event(
            "job_enqueued_by_resource_group",
            user: upcoming.user,
            project: resource_group.project,
            additional_properties: {
              label: resource_group.process_mode,
              property: upcoming.id.to_s,
              resource_group_id: resource_group.id
            }
          )
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def resource_group_assignment_preloads_enabled?(resource_group)
        Feature.enabled?(:resource_group_assignment_preloads, ::Project.actor_from_id(resource_group.project_id))
      end

      # has_outdated_deployment? reaches deployment.environment.last_deployment,
      # which requires a additional preload logic
      def preload_environment_last_deployments(upcoming_processables)
        return if upcoming_processables.empty?

        environments = upcoming_processables.filter_map { |processable| processable.deployment&.environment }.uniq

        ::Preloaders::Environments::DeploymentPreloader.new(environments).execute_with_union(:last_deployment, {})
      end

      def enqueue_upcoming(upcoming)
        enqueued = false

        Gitlab::OptimisticLocking.retry_lock(upcoming, name: 'enqueue_waiting_for_resource') do |processable|
          if processable.has_outdated_deployment?
            processable.drop!(:failed_outdated_deployment_job)
          else
            enqueued = processable.enqueue_waiting_for_resource
          end
        end

        enqueued
      end

      def release_resource_from_stale_jobs(resource_group)
        resource_group.stale_processables.find_each do |processable|
          resource_group.release_resource_from(processable)
        end
      end
    end
  end
end
