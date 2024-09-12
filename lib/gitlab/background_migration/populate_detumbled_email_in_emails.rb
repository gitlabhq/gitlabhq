# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class PopulateDetumbledEmailInEmails < BatchedMigrationJob
      scope_to ->(relation) { relation.where(detumbled_email: nil) }
      operation_name :populate_detumbled_email
      feature_category :user_management

      EMAIL_REGEXP = /\A[^@\s]+@[^@\s]+\z/

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.each do |email|
            email.update!(detumbled_email: normalize_email(email.email))
          end
        end
      end

      private

      # Method copied from lib/gitlab/utils/email.rb
      def normalize_email(email)
        return email unless email.is_a?(String)
        return email unless EMAIL_REGEXP.match?(email.strip)

        portions = email.downcase.strip.split('@')
        mailbox = portions.shift
        domain = portions.join

        mailbox_root = mailbox.split('+')[0]

        # Gmail addresses strip the "." from their emails.
        # For example, user.name@gmail.com is the same as username@gmail.com
        mailbox_root = mailbox_root.tr('.', '') if domain == 'gmail.com'

        [mailbox_root, domain].join('@')
      end
    end
  end
end
