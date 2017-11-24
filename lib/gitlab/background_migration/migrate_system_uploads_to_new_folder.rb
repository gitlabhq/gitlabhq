# frozen_string_literal: true
# rubocop:disable Metrics/LineLength
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class MigrateSystemUploadsToNewFolder
      include Gitlab::Database::MigrationHelpers
      attr_reader :old_folder, :new_folder

      class Upload < ActiveRecord::Base
        self.table_name = 'uploads'
        include EachBatch
      end

      def perform(old_folder, new_folder)
        replace_sql = replace_sql(uploads[:path], old_folder, new_folder)
        affected_uploads = Upload.where(uploads[:path].matches("#{old_folder}%"))

        affected_uploads.each_batch do |batch|
          batch.update_all("path = #{replace_sql}")
        end
      end

      def uploads
        Arel::Table.new('uploads')
      end
    end
  end
end
