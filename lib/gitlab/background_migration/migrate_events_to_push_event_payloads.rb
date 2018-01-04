# frozen_string_literal: true
# rubocop:disable Metrics/LineLength
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    # Class that migrates events for the new push event payloads setup. All
    # events are copied to a shadow table, and push events will also have a row
    # created in the push_event_payloads table.
    class MigrateEventsToPushEventPayloads
      class Event < ActiveRecord::Base
        self.table_name = 'events'

        serialize :data

        BLANK_REF = ('0' * 40).freeze
        TAG_REF_PREFIX = 'refs/tags/'.freeze
        MAX_INDEX = 69
        PUSHED = 5

        def push_event?
          action == PUSHED && data.present?
        end

        def commit_title
          commit = commits.last

          return nil unless commit && commit[:message]

          index = commit[:message].index("\n")
          message = index ? commit[:message][0..index] : commit[:message]

          message.strip.truncate(70)
        end

        def commit_from_sha
          if create?
            nil
          else
            data[:before]
          end
        end

        def commit_to_sha
          if remove?
            nil
          else
            data[:after]
          end
        end

        def data
          super || {}
        end

        def commits
          data[:commits] || []
        end

        def commit_count
          data[:total_commits_count] || 0
        end

        def ref
          data[:ref]
        end

        def trimmed_ref_name
          if ref_type == :tag
            ref[10..-1]
          else
            ref[11..-1]
          end
        end

        def create?
          data[:before] == BLANK_REF
        end

        def remove?
          data[:after] == BLANK_REF
        end

        def push_action
          if create?
            :created
          elsif remove?
            :removed
          else
            :pushed
          end
        end

        def ref_type
          if ref.start_with?(TAG_REF_PREFIX)
            :tag
          else
            :branch
          end
        end
      end

      class EventForMigration < ActiveRecord::Base
        self.table_name = 'events_for_migration'
      end

      class PushEventPayload < ActiveRecord::Base
        self.table_name = 'push_event_payloads'

        enum action: {
          created: 0,
          removed: 1,
          pushed: 2
        }

        enum ref_type: {
          branch: 0,
          tag: 1
        }
      end

      # start_id - The start ID of the range of events to process
      # end_id - The end ID of the range to process.
      def perform(start_id, end_id)
        return unless migrate?

        find_events(start_id, end_id).each { |event| process_event(event) }
      end

      def process_event(event)
        ActiveRecord::Base.transaction do
          replicate_event(event)
          create_push_event_payload(event) if event.push_event?
        end
      rescue ActiveRecord::InvalidForeignKey => e
        # A foreign key error means the associated event was removed. In this
        # case we'll just skip migrating the event.
        Rails.logger.error("Unable to migrate event #{event.id}: #{e}")
      end

      def replicate_event(event)
        new_attributes = event.attributes
          .with_indifferent_access.except(:title, :data)

        EventForMigration.create!(new_attributes)
      end

      def create_push_event_payload(event)
        commit_from = pack(event.commit_from_sha)
        commit_to = pack(event.commit_to_sha)

        PushEventPayload.create!(
          event_id: event.id,
          commit_count: event.commit_count,
          ref_type: event.ref_type,
          action: event.push_action,
          commit_from: commit_from,
          commit_to: commit_to,
          ref: event.trimmed_ref_name,
          commit_title: event.commit_title
        )
      end

      def find_events(start_id, end_id)
        Event
          .where('NOT EXISTS (SELECT true FROM events_for_migration WHERE events_for_migration.id = events.id)')
          .where(id: start_id..end_id)
      end

      def migrate?
        Event.table_exists? && PushEventPayload.table_exists? &&
          EventForMigration.table_exists?
      end

      def pack(value)
        value ? [value].pack('H*') : nil
      end
    end
  end
end
