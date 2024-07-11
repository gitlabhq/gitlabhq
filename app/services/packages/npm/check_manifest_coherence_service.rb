# frozen_string_literal: true

module Packages
  module Npm
    class CheckManifestCoherenceService
      MismatchError = Class.new(StandardError)

      delegate :npm_metadatum, to: :package, private: true
      delegate :package_json_scripts, to: :npm_metadatum, private: true, allow_nil: true

      def initialize(package, package_json_entry)
        @package = package
        @package_json_entry = package_json_entry
      end

      def execute
        parsed_package_json = Gitlab::Json.parse(package_json_entry.read)

        raise MismatchError, 'Package manifest is not coherent' unless coherent?(parsed_package_json)

        ServiceResponse.success
      end

      private

      attr_reader :package, :package_json_entry

      def coherent?(package_json)
        package_json['name'] == package.name &&
          package_json['version'] == package.version &&
          (package_json['scripts'] || {}) == (package_json_scripts || {})
      end
    end
  end
end
