# frozen_string_literal: true

module WebIde
  class ExtensionMarketplaceOptIn
    def self.opt_in_status(user:, marketplace_home_url:)
      return 'unset' unless user && marketplace_home_url
      return 'unset' unless user.extensions_marketplace_opt_in_url == marketplace_home_url

      user.extensions_marketplace_opt_in_status
    end

    def self.enabled?(user:, marketplace_home_url:)
      status = opt_in_status(user: user, marketplace_home_url: marketplace_home_url)

      status == 'enabled'
    end

    def self.params(enabled:, marketplace_home_url:)
      status = ::Gitlab::Utils.to_boolean(enabled) ? 'enabled' : 'disabled'

      {
        extensions_marketplace_opt_in_status: status,
        extensions_marketplace_opt_in_url: marketplace_home_url
      }
    end
  end
end
