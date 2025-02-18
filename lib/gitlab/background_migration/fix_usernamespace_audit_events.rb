# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/database/batched_background_migrations.html
# for more information on how to use batched background migrations

# Update below commented lines with appropriate values.

module Gitlab
  module BackgroundMigration
    class FixUsernamespaceAuditEvents < BatchedMigrationJob
      operation_name :fix_usernamespace_audit_events
      feature_category :audit_events

      def perform
        each_sub_batch do |sub_batch|
          min_created_at, max_created_at = sub_batch.pick(Arel.sql('MIN(created_at), MAX(created_at)'))

          audit_events = sub_batch.where(entity_type: "Namespaces::UserNamespace")
                                  .where(created_at: min_created_at..max_created_at)

          events = audit_events.pluck(:id, :created_at, :author_id, :target_id, :details, :ip_address,
            :author_name, :entity_path, :target_details, :target_type)

          insert_instance_audit_events(events)

          audit_events.update_all(entity_type: "Gitlab::Audit::InstanceScope", entity_id: 1)
        end
      end

      private

      def quote_values(events)
        events.map do |event|
          quoted_event = event.map do |e|
            if e.is_a?(IPAddr)
              connection.quote(e.to_s)
            else
              connection.quote(e)
            end
          end
          "(#{quoted_event.join(', ')})"
        end.join(', ')
      end

      def insert_instance_audit_events(events)
        return if events.empty?

        values = quote_values(events)
        connection.execute <<~SQL
          INSERT INTO instance_audit_events (id, created_at, author_id, target_id, details, ip_address, author_name, entity_path, target_details, target_type)
          VALUES #{values}
          ON CONFLICT (id, created_at) DO NOTHING
        SQL
      end
    end
  end
end
