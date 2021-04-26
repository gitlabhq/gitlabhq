# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # save validity time pages domain
    class FillValidTimeForPagesDomainCertificate
      # define PagesDomain with only needed code
      class PagesDomain < ActiveRecord::Base
        self.table_name = 'pages_domains'

        def x509
          return unless certificate.present?

          @x509 ||= OpenSSL::X509::Certificate.new(certificate)
        rescue OpenSSL::X509::CertificateError
          nil
        end
      end

      def perform(start_id, stop_id)
        PagesDomain.where(id: start_id..stop_id).find_each do |domain|
          # for some reason activerecord doesn't append timezone, iso8601 forces this
          domain.update_columns(
            certificate_valid_not_before: domain.x509&.not_before&.iso8601,
            certificate_valid_not_after: domain.x509&.not_after&.iso8601
          )
        rescue StandardError => e
          Gitlab::AppLogger.error "Failed to update pages domain certificate valid time. id: #{domain.id}, message: #{e.message}"
        end
      end
    end
  end
end
