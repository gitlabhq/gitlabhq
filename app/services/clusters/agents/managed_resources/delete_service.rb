# frozen_string_literal: true

module Clusters
  module Agents
    module ManagedResources
      class DeleteService
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
      end
    end
  end
end
