module Gitlab
  module Geo
    module LogCursor
      module Events
        module BaseEvent
          include Utils::StrongMemoize

          def initialize(event, created_at, logger)
            @event = event
            @created_at = created_at
            @logger = logger
          end

          private

          attr_reader :event, :created_at, :logger

          def registry
            @registry ||= find_or_initialize_registry
          end

          def skippable?
            registry.new_record?
          end

          def healthy_shard_for?(event)
            return true unless event.respond_to?(:project)

            Gitlab::Geo::ShardHealthCache.healthy_shard?(event.project.repository_storage)
          end

          def enqueue_job_if_shard_healthy(event)
            yield if healthy_shard_for?(event)
          end

          def find_or_initialize_registry(attrs = nil)
            ::Geo::ProjectRegistry.find_or_initialize_by(project_id: event.project_id).tap do |registry|
              registry.assign_attributes(attrs)
            end
          end
        end
      end
    end
  end
end
