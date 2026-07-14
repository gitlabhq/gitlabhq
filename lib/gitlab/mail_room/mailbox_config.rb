# frozen_string_literal: true

module Gitlab
  module MailRoom
    # Presents a single mailbox's JWT-related configuration and answers which
    # verification methods it has the credentials for.
    class MailboxConfig
      attr_reader :mailbox_type

      def initialize(config, mailbox_type)
        @config = config || {}
        @mailbox_type = mailbox_type
      end

      def symmetric?
        secret_file.present?
      end

      def asymmetric?
        public_key_files.any?
      end

      def secret_file
        @config[:secret_file]
      end

      def public_key_files
        Array(@config[:public_key_files])
      end
    end
  end
end
