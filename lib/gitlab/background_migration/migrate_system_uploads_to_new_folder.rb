module Gitlab
  module BackgroundMigration
    class MigrateSystemUploadsToNewFolder
      include Gitlab::Database::MigrationHelpers
      attr_reader :old_folder, :new_folder

      def perform(old_folder, new_folder)
        @old_folder = old_folder
        @new_folder = new_folder

        replace_sql = replace_sql(uploads[:path], old_folder, new_folder)

        while remaining_rows > 0
          sql = "UPDATE uploads "\
                "SET path = #{replace_sql} "\
                "WHERE uploads.id IN "\
                "  (SELECT uploads.id FROM uploads "\
                "  WHERE #{affected_uploads.to_sql} LIMIT 1000)"
          connection.execute(sql)
        end
      end

      def uploads
        Arel::Table.new('uploads')
      end

      def remaining_rows
        remaining_result = connection.exec_query("SELECT count(id) FROM uploads WHERE #{affected_uploads.to_sql}")
        remaining = remaining_result.first['count'].to_i
        logger.info "#{remaining} uploads remaining"
        remaining
      end

      def affected_uploads
        uploads[:path].matches("#{old_folder}%")
      end

      def connection
        ActiveRecord::Base.connection
      end

      def logger
        Sidekiq.logger || Rails.logger || Logger.new(STDOUT)
      end
    end
  end
end
