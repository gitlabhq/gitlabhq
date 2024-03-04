# frozen_string_literal: true

module Gitlab
  module Email
    module SingleRecipientValidator
      # It is possible to send email to one or more recipients in one email
      # by setting the list of emails to the :to key, or by :cc or :bcc-ing
      # recipients.
      # https://guides.rubyonrails.org/action_mailer_basics.html#sending-email-to-multiple-recipients
      #
      # This method ensures an email will only go to zero or one recipients.
      def validate_single_recipient_in_opts!(opts)
        return unless opts

        symbolized_opts = opts.symbolize_keys

        if opts.keys.length != symbolized_opts.keys.length
          raise Gitlab::Email::MultipleRecipientsError, "opts has colliding key names"
        end

        if symbolized_opts[:cc] || symbolized_opts[:bcc]
          raise Gitlab::Email::MultipleRecipientsError, 'opts[:cc] and opts[:bcc] are not allowed'
        end

        if symbolized_opts[:to] && !validate_single_recipient_in_email(symbolized_opts[:to])
          raise Gitlab::Email::MultipleRecipientsError, 'opts[:to] must be a string not containing ; or ,'
        end

        true
      end

      # This method validates that only a single recipient is present.
      # It must be a String; e.g. an Array of Strings is not valid.
      # Email separators are commas in RFC5322, but semicolons are also
      # permitted in RFC1485.
      #
      # It does not validate that the recipient is a valid email address.
      def validate_single_recipient_in_email(email)
        email.is_a?(String) && !email.match(/[;,]/)
      end

      def validate_single_recipient_in_email!(email)
        return if validate_single_recipient_in_email(email)

        raise Gitlab::Email::MultipleRecipientsError, 'email must be a string not containing ; or ,'
      end
    end
  end
end
