# frozen_string_literal: true

module Packages
  module Debian
    class SignDistributionService
      include Gitlab::Utils::StrongMemoize

      def initialize(distribution, content, detach: false)
        @distribution = distribution
        @content = content
        @detach = detach
      end

      def execute
        raise ArgumentError, 'distribution key is missing' unless @distribution.key

        sig_mode = GPGME::GPGME_SIG_MODE_CLEAR

        sig_mode = GPGME::GPGME_SIG_MODE_DETACH if @detach

        Gitlab::Gpg.using_tmp_keychain do
          GPGME::Ctx.new(
            armor: true,
            offline: true,
            pinentry_mode: GPGME::PINENTRY_MODE_LOOPBACK,
            password: @distribution.key.passphrase
          ) do |ctx|
            ctx.import(GPGME::Data.from_str(@distribution.key.public_key))
            ctx.import(GPGME::Data.from_str(@distribution.key.private_key))
            signature = GPGME::Data.new
            ctx.sign(GPGME::Data.from_str(@content), signature, sig_mode)
            signature.to_s
          end
        end
      end
    end
  end
end
