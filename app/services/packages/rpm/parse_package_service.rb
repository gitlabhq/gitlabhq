# frozen_string_literal: true

module Packages
  module Rpm
    class ParsePackageService
      include ::Gitlab::Utils::StrongMemoize

      BUILD_ATTRIBUTES_METHOD_NAMES = %i[changelogs requirements provides].freeze
      STATIC_ATTRIBUTES = %i[name version release summary description arch
        license sourcerpm group buildhost packager vendor].freeze

      CHANGELOGS_RPM_KEYS = %i[changelogtext changelogtime].freeze
      REQUIREMENTS_RPM_KEYS = %i[requirename requireversion requireflags].freeze
      PROVIDES_RPM_KEYS = %i[providename provideflags provideversion].freeze

      def initialize(package_file)
        @rpm = RPM::File.new(package_file)
      end

      def execute
        raise ArgumentError, 'Unable to parse package' unless valid_package?

        {
          files: rpm.files || [],
          epoch: package_tags[:epoch] || '0',
          changelogs: build_changelogs,
          requirements: build_requirements,
          provides: build_provides,
          directories: package_tags[:dirnames]
        }.merge(extract_static_attributes)
      end

      private

      attr_reader :rpm

      def valid_package?
        rpm.files && package_tags && true
      rescue RuntimeError
        # if arr-pm throws an error due to an incorrect file format,
        # we just want this validation to fail rather than throw an exception
        false
      end

      def package_tags
        rpm.tags
      end
      strong_memoize_attr :package_tags

      def extract_static_attributes
        STATIC_ATTRIBUTES.index_with do |attribute|
          package_tags[attribute]
        end
      end

      # Define methods for building RPM attribute data from parsed package
      # Transform
      # changelogtime: [123, 234],
      # changelogname: ["First", "Second"]
      # changelogtext: ["Work1", "Work2"]
      # Into
      # changelog: [
      #   {changelogname: "First", changelogtext: "Work1", changelogtime: 123},
      #   {changelogname: "Second", changelogtext: "Work2", changelogtime: 234}
      # ]
      BUILD_ATTRIBUTES_METHOD_NAMES.each do |resource|
        define_method("build_#{resource}") do
          resource_keys = self.class.const_get("#{resource.upcase}_RPM_KEYS", false).dup
          return [] if resource_keys.any? { package_tags[_1].blank? }

          first_attributes = package_tags[resource_keys.first]
          zipped_data = first_attributes.zip(*resource_keys[1..].map { package_tags[_1] })
          build_hashes(resource_keys, zipped_data)
        end
      end

      def build_hashes(resource_keys, zipped_data)
        zipped_data.map do |data|
          resource_keys.zip(data).to_h
        end
      end
    end
  end
end
