# frozen_string_literal: true

module Packages
  module Go
    class CreatePackageService < BaseService
      GoZipSizeError = Class.new(StandardError)

      attr_accessor :version

      def initialize(project, user = nil, version:)
        super(project, user)

        @version = version
      end

      def execute
        # check for existing package to avoid SQL errors due to the index
        package = ::Packages::Go::PackageFinder.new(version.mod.project, version.mod.name, version.name).execute
        return package if package

        # this can be expensive, so do it outside the transaction
        files = {}
        files[:mod] = prepare_file(version, :mod, version.gomod)
        files[:zip] = prepare_file(version, :zip, version.archive.string)

        ApplicationRecord.transaction do
          # create new package and files
          package = create_package
          files.each { |type, (file, digests)| create_file(package, type, file, digests) }
          package
        end
      end

      private

      def prepare_file(version, type, content)
        file = CarrierWaveStringFile.new(content)
        raise GoZipSizeError, "#{version.mod.name}@#{version.name}.#{type} exceeds size limit" if file.size > project.actual_limits.golang_max_file_size

        digests = {
          md5: Digest::MD5.hexdigest(content),
          sha1: Digest::SHA1.hexdigest(content),
          sha256: Digest::SHA256.hexdigest(content)
        }

        [file, digests]
      end

      def create_package
        version.mod.project.packages.create!(
          name: version.mod.name,
          version: version.name,
          package_type: :golang,
          created_at: version.commit.committed_date
        )
      end

      def create_file(package, type, file, digests)
        CreatePackageFileService.new(package,
          file: file,
          size: file.size,
          file_name: "#{version.name}.#{type}",
          file_md5: digests[:md5],
          file_sha1: digests[:sha1],
          file_sha256: digests[:sha256]
        ).execute
      end
    end
  end
end
