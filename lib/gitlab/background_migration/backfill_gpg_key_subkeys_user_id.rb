# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillGpgKeySubkeysUserId < BackfillDesiredShardingKeyJob
      operation_name :backfill_gpg_key_subkeys_user_id
      feature_category :source_code_management
    end
  end
end
