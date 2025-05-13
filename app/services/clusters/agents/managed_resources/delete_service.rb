# frozen_string_literal: true

module Clusters
  module Agents
    module ManagedResources
      class DeleteService
        CORE_GROUP = 'core'
        POLLING_SCHEDULE = [
          10.seconds,
          30.seconds,
          5.minutes,
          30.minutes,
          1.hour
        ].freeze

        def initialize(managed_resource, attempt_count: nil)
          @managed_resource = managed_resource
          @attempt_count = attempt_count || 0
        end

        def execute
          return unless managed_resource.deleting?

          response = kas_client.delete_environment(managed_resource:)

          if response.errors.any?
            requeue!

            response.errors.each do |error|
              log_error(details: format_error(error))
            end

            return
          end

          managed_resource.update!(tracked_objects: response.in_progress.map(&:to_h))

          if managed_resource.tracked_objects.any?
            requeue!
          else
            update_status!(:deleted)
          end
        end

        private

        attr_reader :managed_resource, :attempt_count

        def requeue!
          if attempt_count >= POLLING_SCHEDULE.length
            update_status!(:delete_failed)
            log_error(details: 'timeout')
          else
            next_attempt_in = POLLING_SCHEDULE[attempt_count]

            Clusters::Agents::ManagedResources::DeleteWorker.perform_in(next_attempt_in, managed_resource.id,
              attempt_count + 1)
          end
        end

        def update_status!(status)
          managed_resource.update!(status: status)
        end

        def kas_client
          @kas_client ||= Gitlab::Kas::Client.new
        end

        def format_error(error)
          object = error.object
          group = object.group.presence || CORE_GROUP

          object_details = "#{group}/#{object.version}/#{object.kind} '#{object.name}'"
          object_details += " in namespace '#{object.namespace}'" if object.namespace.present?

          "#{object_details} failed with message '#{error.error}'"
        end

        def log_error(details:)
          logger.error(
            message: "Error deleting managed resources: #{details}",
            agent_id: managed_resource.cluster_agent_id,
            environment_id: managed_resource.environment_id
          )
        end

        def logger
          @logger ||= Gitlab::Kubernetes::Logger.build
        end
      end
    end
  end
end
