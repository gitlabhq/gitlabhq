# frozen_string_literal: true

module Packages
  module Npm
    class CheckManifestCoherenceService
      MismatchError = Class.new(StandardError)

      PKG_TYPE = 'npm'
      MANIFEST_NOT_COHERENT_ERROR = 'Package manifest is not coherent'
      VERSION_NOT_COMPLIANT_ERROR = 'Version in package.json is not SemVer compliant'

      def initialize(package, package_json_entry)
        @package = package
        @package_json_entry = package_json_entry
      end

      def execute
        parsed_package_json = Gitlab::Json.parse(package_json_entry.read)

        raise MismatchError, MANIFEST_NOT_COHERENT_ERROR unless coherent?(parsed_package_json)

        ServiceResponse.success
      end

      private

      attr_reader :package, :package_json_entry

      def coherent?(package_json)
        package_json['name'] == package.name &&
          same_version?(package_json['version'], package.version)
      end

      def same_version?(version1, version2)
        v1 = SemverDialects.parse_version(PKG_TYPE, version1)
        v2 = SemverDialects.parse_version(PKG_TYPE, version2)

        v1 == v2
      rescue SemverDialects::InvalidVersionError
        raise MismatchError, VERSION_NOT_COMPLIANT_ERROR
      end
    end
  end
end
