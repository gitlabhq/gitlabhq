# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill project_settings for a range of projects
    class BackfillProjectSettings
      def perform(start_id, end_id)
        ActiveRecord::Base.connection.execute <<~SQL
          INSERT INTO project_settings (project_id, created_at, updated_at)
            SELECT projects.id, now(), now()
            FROM projects
            WHERE projects.id BETWEEN #{start_id} AND #{end_id}
          ON CONFLICT (project_id) DO NOTHING;
        SQL
      end
    end
  end
end
