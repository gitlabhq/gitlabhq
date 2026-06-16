# frozen_string_literal: true

module Packages
  module Rubygems
    class CreateSpecFilesService
      include Gitlab::Utils::StrongMemoize
      include ExclusiveLeaseGuard

      # used by ExclusiveLeaseGuard
      DEFAULT_LEASE_TIMEOUT = 1.hour.to_i.freeze

      SPEC_FILE_NAME = 'specs.4.8.gz'
      LATEST_SPEC_FILE_NAME = 'latest_specs.4.8.gz'
      PRERELEASE_SPEC_FILE_NAME = 'prerelease_specs.4.8.gz'

      SPEC_FILES = {
        SPEC_FILE_NAME => :released,
        LATEST_SPEC_FILE_NAME => :latest,
        PRERELEASE_SPEC_FILE_NAME => :prerelease
      }.freeze

      def initialize(project)
        @project = project
      end

      def execute
        errors = []

        try_obtain_lease do
          SPEC_FILES.each do |file_name, bucket|
            update_spec_file(file_name, gzip_marshal_dump(spec_buckets[bucket]))
          rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
            errors << e.message
          end
        end

        return ServiceResponse.error(message: errors.join(', ')) if errors.any?

        ServiceResponse.success
      end

      private

      attr_reader :project

      def spec_buckets
        released = []
        prerelease = []

        ::Packages::Rubygems::Package
          .installable_for_project(project)
          .each_batch do |batch|
            # rubocop:disable CodeReuse/ActiveRecord, Database/AvoidUsingPluckWithoutLimit -- bounded by each_batch
            batch
              .left_joins(:rubygems_metadatum)
              .pluck(:name, :version, rubygems_metadatum: %i[platform])
              .each do |name, version_str, platform|
                version = Gem::Version.new(version_str)
                spec = [name, version, platform || Gem::Platform::RUBY]
                (version.prerelease? ? prerelease : released) << spec
              end
            # rubocop:enable CodeReuse/ActiveRecord, Database/AvoidUsingPluckWithoutLimit
          end

        released.sort_by!   { |n, v, p| [n, v, p.to_s] }
        prerelease.sort_by! { |n, v, p| [n, v, p.to_s] }
        latest = released.index_by(&:first).values

        { released: released, latest: latest, prerelease: prerelease }
      end
      strong_memoize_attr :spec_buckets

      def gzip_marshal_dump(specs)
        StringIO.open(+'') do |io|
          Zlib::GzipWriter.wrap(io) do |gzip|
            gzip.mtime = 0
            Marshal.dump(specs, gzip)
          end

          io.string
        end
      end

      def update_spec_file(file_name, content)
        spec_file = ::Packages::Rubygems::SpecFile.find_or_build(
          project_id: project.id,
          file_name: file_name
        )

        spec_file.update!(
          file: CarrierWaveStringFile.new(content),
          size: content.bytesize
        )
      end

      # used by ExclusiveLeaseGuard
      def lease_key
        "packages:rubygems:create_spec_files_service:#{project.id}"
      end

      # used by ExclusiveLeaseGuard
      def lease_timeout
        DEFAULT_LEASE_TIMEOUT
      end
    end
  end
end
