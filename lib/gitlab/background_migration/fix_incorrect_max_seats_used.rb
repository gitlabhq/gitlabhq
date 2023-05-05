# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Style/Documentation
    class FixIncorrectMaxSeatsUsed
      def perform(batch = nil)
      end
    end
  end
end

Gitlab::BackgroundMigration::FixIncorrectMaxSeatsUsed.prepend_mod_with('Gitlab::BackgroundMigration::FixIncorrectMaxSeatsUsed')
