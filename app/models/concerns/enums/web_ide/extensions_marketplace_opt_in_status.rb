# frozen_string_literal: true

module Enums
  module WebIde
    module ExtensionsMarketplaceOptInStatus
      def self.statuses
        { unset: 0, enabled: 1, disabled: 2 }
      end
    end
  end
end
