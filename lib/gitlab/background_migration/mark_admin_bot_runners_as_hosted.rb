# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class doesn't create SecuritySetting
    # as this feature exists only in EE
    class MarkAdminBotRunnersAsHosted < BatchedMigrationJob
      feature_category :hosted_runners

      def perform; end
    end
  end
end

# rubocop:disable Layout/LineLength -- If I do multiline, another cop complains about prepend should be last line
Gitlab::BackgroundMigration::MarkAdminBotRunnersAsHosted.prepend_mod_with('Gitlab::BackgroundMigration::MarkAdminBotRunnersAsHosted')
# rubocop:enable Layout/LineLength
