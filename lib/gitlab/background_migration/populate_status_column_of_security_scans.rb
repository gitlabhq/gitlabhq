# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class PopulateStatusColumnOfSecurityScans # rubocop:disable Style/Documentation
      def perform(_start_id, _end_id)
        # no-op
      end
    end
  end
end

Gitlab::BackgroundMigration::PopulateStatusColumnOfSecurityScans.prepend_mod
