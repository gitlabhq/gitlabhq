# frozen_string_literal: true

module Gitlab
  module ServiceDeskEmail
    class << self
      def enabled?
        !!config&.enabled && config&.address.present?
      end

      def key_from_address(address)
        wildcard_address = config&.address
        return unless wildcard_address

        Gitlab::IncomingEmail.key_from_address(address, wildcard_address: wildcard_address)
      end

      def config
        Gitlab.config.service_desk_email
      end
    end
  end
end
