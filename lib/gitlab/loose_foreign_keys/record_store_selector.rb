# frozen_string_literal: true

module Gitlab
  module LooseForeignKeys
    # Selects the LFK record store used by cleanup workers.
    #
    # Returns the Gitlab::LooseForeignKeys::DeletedRecordStore facade (which fans cleanup across all 5 LFK models)
    # when use_loose_foreign_keys_deleted_record_store is enabled, otherwise falls back to the cell-local
    # LooseForeignKeys::DeletedRecord.
    #
    # The concern and the flag will be removed in Phase 5: https://gitlab.com/gitlab-org/gitlab/-/issues/597949
    module RecordStoreSelector
      def flipper_id
        self.class.to_s
      end

      private

      def record_store
        if Feature.enabled?(:use_loose_foreign_keys_deleted_record_store, self, type: :gitlab_com_derisk)
          ::Gitlab::LooseForeignKeys::DeletedRecordStore
        else
          ::LooseForeignKeys::DeletedRecord
        end
      end
    end
  end
end
