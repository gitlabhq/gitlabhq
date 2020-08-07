# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class is responsible for migrating a range of merge request diffs
    # with external_diff_store == NULL to 1.
    #
    # The index `index_merge_request_diffs_external_diff_store_is_null` is
    # expected to be used to find the rows here and in the migration scheduling
    # the jobs that run this class.
    class SetNullExternalDiffStoreToLocalValue
      LOCAL_STORE = 1 # equal to ObjectStorage::Store::LOCAL

      # Temporary AR class for merge request diffs
      class MergeRequestDiff < ActiveRecord::Base
        self.table_name = 'merge_request_diffs'
      end

      def perform(start_id, stop_id)
        MergeRequestDiff.where(external_diff_store: nil, id: start_id..stop_id).update_all(external_diff_store: LOCAL_STORE)
      end
    end
  end
end
