# frozen_string_literal: true

module Gitlab
  module Email
    module Hook
      class SmimeSignatureInterceptor
        # Sign emails with SMIME if enabled
        class << self
          def delivering_email(message)
            signed_message = Gitlab::Email::Smime::Signer.sign(
              cert: certificate.cert,
              key: certificate.key,
              ca_certs: certificate.ca_certs,
              data: message.encoded)

            signed_email = Mail.new(signed_message)

            overwrite_body(message, signed_email)
            overwrite_headers(message, signed_email)
          end

          private

          def certificate
            @certificate ||= Gitlab::X509::Certificate.from_files(key_path, cert_path, ca_certs_path)
          end

          def key_path
            Gitlab.config.gitlab.email_smime.key_file
          end

          def cert_path
            Gitlab.config.gitlab.email_smime.cert_file
          end

          def ca_certs_path
            Gitlab.config.gitlab.email_smime.ca_certs_file
          end

          def overwrite_body(message, signed_email)
            # since this is a multipart email, assignment to nil is important,
            # otherwise Message#body will add a new mail part
            message.body = nil
            message.body = signed_email.body.encoded
          end

          def overwrite_headers(message, signed_email)
            message.content_transfer_encoding = signed_email.content_transfer_encoding
            message.content_type = signed_email.content_type
          end
        end
      end
    end
  end
end
