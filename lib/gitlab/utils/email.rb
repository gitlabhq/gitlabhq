# frozen_string_literal: true

module Gitlab
  module Utils
    module Email
      extend self

      # Replaces most visible characters with * to obfuscate an email address
      # deform adds a fix number of * to ensure the address cannot be guessed. Also obfuscates TLD with **
      def obfuscated_email(email, deform: false)
        regex = ::Gitlab::UntrustedRegexp.new('^(..?)(.*)(@.?)(.*)(\..+)$')
        match = regex.match(email)
        return email unless match

        if deform
          # Ensure we can show two characters for the username, even if the username has
          # only one character. Boring solution is to just duplicate the character.
          email_start = match[1]
          email_start += email_start if email_start.length == 1

          email_start + '*' * 5 + match[3] + '*' * 5 + "#{match[5][0..1]}**"
        else
          match[1] + '*' * (match[2] || '').length + match[3] + '*' * (match[4] || '').length + match[5]
        end
      end
    end
  end
end
