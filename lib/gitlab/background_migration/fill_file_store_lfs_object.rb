# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class FillFileStoreLfsObject
      class LfsObject < ActiveRecord::Base
        self.table_name = 'lfs_objects'
      end

      def perform(start_id, stop_id)
        FillFileStoreLfsObject::LfsObject
          .where(file_store: nil)
          .where(id: (start_id..stop_id))
          .update_all(file_store: 1)
      end
    end
  end
end
