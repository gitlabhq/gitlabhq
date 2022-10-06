# frozen_string_literal: true

module Gitlab
  module Ci
    module SecureFiles
      class Cer
        attr_reader :error

        def initialize(filedata)
          @filedata = filedata
          @error    = nil
        end

        def certificate_data
          @certificate_data ||= begin
            OpenSSL::X509::Certificate.new(@filedata)
          rescue StandardError => err
            @error = err.to_s
            nil
          end
        end

        def metadata
          return {} unless certificate_data

          {
            issuer: issuer,
            subject: subject,
            id: id,
            expires_at: expires_at
          }
        end

        def expires_at
          return unless certificate_data

          certificate_data.not_before
        end

        private

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
