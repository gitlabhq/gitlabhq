# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class doesn't create SecuritySetting
    # as this feature exists only in EE
    class CreateSecuritySetting
      def perform(_from_id, _to_id); end
    end
  end
end

Gitlab::BackgroundMigration::CreateSecuritySetting.prepend_mod_with('Gitlab::BackgroundMigration::CreateSecuritySetting')
