# frozen_string_literal: true

module Gitlab
  module Email
    # Contains common methods which must be present in all email classes
    module Common
      UNSUBSCRIBE_SUFFIX        = '-unsubscribe'
      UNSUBSCRIBE_SUFFIX_LEGACY = '+unsubscribe'
      WILDCARD_PLACEHOLDER      = '%{key}'

      # This can be overridden for a custom config
      def config
        raise NotImplementedError
      end

      def incoming_email_config
        Gitlab.config.incoming_email
      end

      def enabled?
        !!config&.enabled && config.address.present?
      end

      def supports_wildcard?
        config_address = incoming_email_config.address

        config_address.present? && config_address.include?(WILDCARD_PLACEHOLDER)
      end

      def supports_issue_creation?
        enabled? && supports_wildcard?
      end

      def reply_address(key)
        incoming_email_config.address.sub(WILDCARD_PLACEHOLDER, key)
      end

      # example: incoming+1234567890abcdef1234567890abcdef-unsubscribe@incoming.gitlab.com
      def unsubscribe_address(key)
        incoming_email_config.address.sub(WILDCARD_PLACEHOLDER, "#{key}#{UNSUBSCRIBE_SUFFIX}")
      end

      def key_from_address(address, wildcard_address: nil)
        raise NotImplementedError
      end

      def key_from_fallback_message_id(mail_id)
        message_id_regexp = /\Areply-(.+)@#{Gitlab.config.gitlab.host}\z/

        mail_id[message_id_regexp, 1]
      end

      def scan_fallback_references(references)
        # It's looking for each <...>
        references.scan(/(?!<)[^<>]+(?=>)/)
      end

      def encrypted_secrets
        Settings.encrypted(config.encrypted_secret_file)
      end
    end
  end
end
