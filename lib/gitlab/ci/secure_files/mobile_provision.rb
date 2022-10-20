# frozen_string_literal: true
require 'cfpropertylist'

module Gitlab
  module Ci
    module SecureFiles
      class MobileProvision
        include Gitlab::Utils::StrongMemoize

        attr_reader :error

        def initialize(filedata)
          @filedata = filedata
        end

        def decoded_plist
          p7 = OpenSSL::PKCS7.new(@filedata)
          p7.verify(nil, OpenSSL::X509::Store.new, nil, OpenSSL::PKCS7::NOVERIFY)
          p7.data
        rescue ArgumentError, OpenSSL::PKCS7::PKCS7Error => err
          @error = err.to_s
          nil
        end
        strong_memoize_attr :decoded_plist

        def properties
          list = CFPropertyList::List.new(data: decoded_plist, format: CFPropertyList::List::FORMAT_XML).value
          CFPropertyList.native_types(list)
        rescue CFFormatError, CFPlistError, CFTypeError => err
          @error = err.to_s
          nil
        end
        strong_memoize_attr :properties

        def metadata
          return {} unless properties

          {
            id: id,
            expires_at: expires_at,
            platforms: properties["Platform"],
            team_name: properties['TeamName'],
            team_id: properties['TeamIdentifier'],
            app_name: properties['AppIDName'],
            app_id: properties['Name'],
            app_id_prefix: properties['ApplicationIdentifierPrefix'],
            xcode_managed: properties['IsXcodeManaged'],
            entitlements: properties['Entitlements'],
            devices: properties['ProvisionedDevices'],
            certificate_ids: certificate_ids
          }
        end
        strong_memoize_attr :metadata

        private

        def id
          properties['UUID']
        end

        def expires_at
          properties['ExpirationDate']
        end

        def certificate_ids
          return [] if developer_certificates.empty?

          developer_certificates.map { |c| c.metadata[:id] }
        end

        def developer_certificates
          certificates = properties['DeveloperCertificates']
          return if certificates.empty?

          certs = []
          certificates.each_with_object([]) do |cert, obj|
            certs << Cer.new(cert)
          end

          certs
        end
      end
    end
  end
end
