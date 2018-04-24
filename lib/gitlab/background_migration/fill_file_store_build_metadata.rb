# frozen_string_literal: true
# rubocop:disable Metrics/AbcSize
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class FillFileStoreBuildMetadata
      class Build < ActiveRecord::Base
        self.table_name = 'ci_builds'
        self.inheritance_column = :_type_disabled
      end

      def perform(start_id, stop_id)
        FillFileStoreBuildMetadata::Build
          .where('artifacts_metadata_store = NULL')
          .where(id: (start_id..stop_id))
          .update_all(artifacts_metadata_store: 1)
      end
    end
  end
end
