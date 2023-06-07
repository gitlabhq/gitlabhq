# frozen_string_literal: true

module Packages
  module Debian
    class GenerateDistributionKeyService
      include Gitlab::Utils::StrongMemoize

      def initialize(params: {})
        @params = params
      end

      def execute
        using_pinentry do |ctx|
          # Generate key
          ctx.generate_key generate_key_params

          key = ctx.keys.first # rubocop:disable Gitlab/KeysFirstAndValuesFirst
          fingerprint = key.fingerprint

          # Export private key
          data = GPGME::Data.new
          ctx.export_keys fingerprint, data, GPGME::EXPORT_MODE_SECRET
          data.seek 0
          private_key = data.read

          # Export public key
          data = GPGME::Data.new
          ctx.export_keys fingerprint, data
          data.seek 0
          public_key = data.read

          {
            private_key: private_key,
            public_key: public_key,
            passphrase: passphrase,
            fingerprint: fingerprint
          }
        end
      end

      private

      attr_reader :params

      def passphrase
        params[:passphrase] || ::User.random_password
      end
      strong_memoize_attr :passphrase

      def pinentry_script_content
        escaped_passphrase = Shellwords.escape(passphrase)

        <<~EOF
        #!/bin/sh

        echo OK Pleased to meet you

        while read -r cmd; do
          case "$cmd" in
            GETPIN) echo D #{escaped_passphrase}; echo OK;;
            *) echo OK;;
          esac
        done
        EOF
      end

      def using_pinentry
        Gitlab::Gpg.using_tmp_keychain do
          home_dir = Gitlab::Gpg.current_home_dir

          File.write("#{home_dir}/pinentry.sh", pinentry_script_content, mode: 'w', perm: 0755)

          File.write("#{home_dir}/gpg-agent.conf", "pinentry-program #{home_dir}/pinentry.sh\n", mode: 'w')

          GPGME::Ctx.new(armor: true, offline: true) do |ctx|
            yield ctx
          end
        end
      end

      def generate_key_params
        # https://www.gnupg.org/documentation/manuals/gnupg/Unattended-GPG-key-generation.html
        '<GnupgKeyParms format="internal">' + "\n" +
          {
            'Key-Type': params[:key_type] || 'RSA',
            'Key-Length': params[:key_length] || 4096,
            'Key-Usage': params[:key_usage] || 'sign',
            'Name-Real': params[:name_real] || 'GitLab Debian repository',
            'Name-Email': params[:name_email] || Gitlab.config.gitlab.email_reply_to,
            'Name-Comment': params[:name_comment] || 'GitLab Debian repository automatic signing key',
            'Expire-Date': params[:expire_date] || 0,
            Passphrase: passphrase
          }.map { |k, v| "#{k}: #{v}\n" }.join +
          '</GnupgKeyParms>'
      end
    end
  end
end
