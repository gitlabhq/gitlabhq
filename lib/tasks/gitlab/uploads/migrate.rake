require 'gitlab/utils/bisect_enumerable.rb'
require_relative 'helpers.rb'

module UploadTask
  module Migrate
    class MigrationResult
      attr_reader :upload
      attr_accessor :error

      def initialize(upload, error = nil)
        @upload, @error = upload, error
      end

      def success?
        error.nil?
      end

      def to_s
        success? ? "Migration sucessful." : "Error while migrating #{upload.id}: #{error.message}"
      end
    end

    class Reporter
      def initialize(results = [])
        @success, @failures = Gitlab::Utils::BisectEnumerable.bisect(results, &:success?)
      end

      def report
        puts header
        puts failures
      end

      def header
        color = @failures.count == 0 ? :green : :red

        "Migrated #{@success.count}/#{@success.count + @failures.count} files.".color(color)
      end

      def failures
        @failures.map { |f| "\t#{f}".color(:red) }.join('\n')
      end
    end

    class Migrator
      attr_reader :to_store

      def initialize(uploader_class, model_class, mounted_as, to_store)
        @results = []
        @uploader_class, @model_class = uploader_class, model_class
        @mounted_as = mounted_as
        @to_store = to_store
      end

      def build_uploaders(uploads)
        uploads.map { |upload| upload.build_uploader(@mounted_as) }
      end

      def migrate(batch_size, &block)
        each_upload_batch(batch_size) do |batch|
          results = build_uploaders(batch)
                      .map(&method(:process_uploader))
          yield results # yield processed batch as [MigrationResult]
          @results.concat(results)
        end
      end

      def report
        Reporter.new(@results).report
      end

      def each_upload_batch(batch_size, &block)
        Upload.preload(:model)
          .where.not(store: @to_store)
          .where(uploader: @uploader_class.to_s,
                 model_type: @model_class.to_s)
          .in_batches(of: batch_size, &block)
      end

      def process_uploader(uploader)
        result = MigrationResult.new(uploader.upload)
        begin
          uploader.migrate!(@to_store)
          result
        rescue => e
          result.error = e
          result
        end
      end
    end
  end
end

namespace :gitlab do
  namespace :uploads do
    desc 'GitLab | Uploads | Migrate the uploaded files to object storage'
    task :migrate, [:uploader_class, :model_class, :mounted_as] => :environment do |task, args|
      uploader_class = args.uploader_class.constantize
      model_class = args.model_class.constantize
      mounted_as = args.mounted_as&.gsub(':', '')&.to_sym

      migrator = UploadTask::Migrate::Migrator.new(
        uploader_class,
        model_class,
        mounted_as,
        ObjectStorage::Store::LOCAL
      )

      migrator.migrate(batch_size) do |results|
        UploadTask::Migrate::Reporter.new(results).report
      end

      puts "\n === Migration summary ==="
      migrator.report
    end
  end
end
