# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class FillStoreUpload
      class Upload < ActiveRecord::Base
        self.table_name = 'uploads'
        self.inheritance_column = :_type_disabled
      end

      def perform(start_id, stop_id)
        FillStoreUpload::Upload
          .where(store: nil)
          .where(id: (start_id..stop_id))
          .update_all(store: 1)
      end
    end
  end
end
