# frozen_string_literal: true

require 'rubygems/package'

module Packages
  module Rubygems
    class ProcessGemService
      include Gitlab::Utils::StrongMemoize
      include ExclusiveLeaseGuard

      ExtractionError = Class.new(StandardError)
      DEFAULT_LEASE_TIMEOUT = 1.hour.to_i.freeze

      def initialize(package_file)
        @package_file = package_file
      end

      def execute
        raise ExtractionError, 'Gem was not processed - package_file is not set' unless package_file
        return success if process_gem

        error('Gem was not processed')
      end

      private

      attr_reader :package_file

      def process_gem
        try_obtain_lease do
          package.transaction do
            rename_package_and_set_version
            rename_package_file
            ::Packages::Rubygems::MetadataExtractionService.new(package, gemspec).execute
            ::Packages::Rubygems::CreateGemspecService.new(package, gemspec).execute
            ::Packages::Rubygems::CreateDependenciesService.new(package, gemspec).execute
            cleanup_temp_package
          end
        end

        true
      end

      def rename_package_and_set_version
        package.update!(
          name: gemspec.name,
          version: gemspec.version,
          status: :default
        )
      end

      def rename_package_file
        # Updating file_name updates the path where the file is stored.
        # We must pass the file again so that CarrierWave can handle the update
        package_file.update!(
          file_name: "#{gemspec.name}-#{gemspec.version}.gem",
          file: package_file.file,
          package_id: package.id
        )
      end

      def cleanup_temp_package
        temp_package.destroy if package.id != temp_package.id
      end

      def gemspec
        strong_memoize(:gemspec) do
          gem.spec
        end
      end

      def success
        ServiceResponse.success(payload: { package: package })
      end

      def error(message)
        ServiceResponse.error(message: message)
      end

      def temp_package
        strong_memoize(:temp_package) do
          package_file.package
        end
      end

      def package
        strong_memoize(:package) do
          # if package with name/version already exists, use that package
          package = temp_package.project
                                .packages
                                .rubygems
                                .with_name(gemspec.name)
                                .with_version(gemspec.version.to_s)
                                .last
          package || temp_package
        end
      end

      def gem
        # use_file will set an exclusive lease on the file for as long as
        # the resulting gem object is being used. This means we are not
        # able to rename the package_file while also using the gem object.
        # We need to use a separate AR object to create the gem file to allow
        # `package_file` to be free for update so we re-find the file here.
        Packages::PackageFile.find(package_file.id).file.use_file do |file_path|
          Gem::Package.new(File.open(file_path))
        end
      rescue StandardError
        raise ExtractionError, 'Unable to read gem file'
      end

      # used by ExclusiveLeaseGuard
      def lease_key
        "packages:rubygems:process_gem_service:package:#{package.id}"
      end

      # used by ExclusiveLeaseGuard
      def lease_timeout
        DEFAULT_LEASE_TIMEOUT
      end
    end
  end
end
