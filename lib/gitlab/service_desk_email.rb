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

      def address_for_key(key)
        return if config.address.blank?

        config.address.sub(Gitlab::IncomingEmail::WILDCARD_PLACEHOLDER, key)
      end

      def key_from_fallback_message_id(mail_id)
        message_id_regexp = /\Areply\-(.+)@#{Gitlab.config.gitlab.host}\z/

        mail_id[message_id_regexp, 1]
      end
    end
  end
end
