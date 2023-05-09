# frozen_string_literal: true

module Gitlab
  module Ci
    module SecureFiles
      class Cer
        include Gitlab::Utils::StrongMemoize

        attr_reader :error

        def initialize(filedata)
          @filedata = filedata
          @error    = nil
        end

        def certificate_data
          OpenSSL::X509::Certificate.new(@filedata)
        rescue OpenSSL::X509::CertificateError => err
          @error = err.to_s
          nil
        end
        strong_memoize_attr :certificate_data

        def metadata
          return {} unless certificate_data

          {
            issuer: issuer,
            subject: subject,
            id: id,
            expires_at: expires_at
          }
        end
        strong_memoize_attr :metadata

        private

        def expires_at
          certificate_data.not_after
        end

        def id
          certificate_data.serial.to_s
        end

        def issuer
          X509Name.parse(certificate_data.issuer)
        end

        def subject
          X509Name.parse(certificate_data.subject)
        end
      end
    end
  end
end
