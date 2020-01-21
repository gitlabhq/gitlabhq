# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Style/Documentation
    class UpdateAuthorizedKeysFileSince
      def perform(cutoff_datetime)
      end
    end
  end
end

Gitlab::BackgroundMigration::UpdateAuthorizedKeysFileSince.prepend_if_ee('EE::Gitlab::BackgroundMigration::UpdateAuthorizedKeysFileSince')
