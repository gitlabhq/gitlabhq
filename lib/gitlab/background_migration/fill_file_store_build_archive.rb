# frozen_string_literal: true
# rubocop:disable Metrics/AbcSize
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class FillFileStoreBuildArchive
      class Build < ActiveRecord::Base
        self.table_name = 'ci_builds'
        self.inheritance_column = :_type_disabled
      end

      def perform(start_id, stop_id)
        FillFileStoreBuildArchive::Build
          .where('artifacts_file_store = NULL')
          .where(id: (start_id..stop_id))
          .update_all(artifacts_file_store: 1)
      end
    end
  end
end
