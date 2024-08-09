# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillNewAuditEventTables < BatchedMigrationJob
      operation_name :migrate_audit_events
      feature_category :audit_events

      def perform
        each_sub_batch do |sub_batch|
          audit_events = sub_batch.pluck(:id, :created_at, :author_id, :target_id, :details, :ip_address,
            :author_name, :entity_path, :target_details, :target_type,
            :entity_id, :entity_type)

          project_audit_events = []
          group_audit_events = []
          user_audit_events = []
          instance_audit_events = []

          audit_events.each do |event|
            case event.last
            when 'Project'
              project_audit_events << event[0..-2]
            when 'Group'
              group_audit_events << event[0..-2]
            when 'User'
              user_audit_events << event[0..-2]
            when 'Gitlab::Audit::InstanceScope'
              instance_audit_events << event[0..-3]
            end
          end

          insert_project_audit_events(project_audit_events)
          insert_group_audit_events(group_audit_events)
          insert_user_audit_events(user_audit_events)
          insert_instance_audit_events(instance_audit_events)
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

      def insert_project_audit_events(events)
        return if events.empty?

        values = quote_values(events)
        connection.execute <<~SQL
          INSERT INTO project_audit_events (id, created_at, author_id, target_id, details, ip_address, author_name, entity_path, target_details, target_type, project_id)
          VALUES #{values}
          ON CONFLICT (id, created_at) DO NOTHING
        SQL
      end

      def insert_group_audit_events(events)
        return if events.empty?

        values = quote_values(events)
        connection.execute <<~SQL
          INSERT INTO group_audit_events (id, created_at, author_id, target_id, details, ip_address, author_name, entity_path, target_details, target_type, group_id)
          VALUES #{values}
          ON CONFLICT (id, created_at) DO NOTHING
        SQL
      end

      def insert_user_audit_events(events)
        return if events.empty?

        values = quote_values(events)
        connection.execute <<~SQL
          INSERT INTO user_audit_events (id, created_at, author_id, target_id, details, ip_address, author_name, entity_path, target_details, target_type, user_id)
          VALUES #{values}
          ON CONFLICT (id, created_at) DO NOTHING
        SQL
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
