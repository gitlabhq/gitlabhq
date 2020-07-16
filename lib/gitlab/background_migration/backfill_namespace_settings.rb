# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfillnamespace_settings for a range of namespaces
    class BackfillNamespaceSettings
      def perform(start_id, end_id)
        ActiveRecord::Base.connection.execute <<~SQL
          INSERT INTO namespace_settings (namespace_id, created_at, updated_at)
            SELECT namespaces.id, now(), now()
            FROM namespaces
            WHERE namespaces.id BETWEEN #{start_id} AND #{end_id}
          ON CONFLICT (namespace_id) DO NOTHING;
        SQL
      end
    end
  end
end
