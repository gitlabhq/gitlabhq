# frozen_string_literal: true

# File Download Service orchestrates remote file download into tmp directory according to configuration context.
module BulkImports
  class FileDownloadService
    # @param context [BulkImports::Context] Context object containing connection credentials
    # @param relation [String] Relation type being downloaded.
    # @param tmpdir [String] Temp directory to store downloaded file to. Must be located under `Dir.tmpdir`.
    # @param filename [String] Name of the file to download.
    def self.for_context(context:, relation:, tmpdir:, filename:)
      if context.offline?
        object_key = Import::Offline::ObjectKeyBuilder.new(context.offline_configuration)
          .download_object_key(
            relation: relation,
            extension: filename.delete_prefix(relation),
            entity_source_full_path: context.entity.source_full_path,
            batch_number: context.extra[:batch_number]
          )

        file_download_strategy = Import::Offline::Imports::ObjectStorageFileDownloadStrategy.new(
          offline_configuration: context.offline_configuration, object_key: object_key
        )
      else
        file_download_strategy = Import::BulkImports::HttpFileDownloadStrategy.new(
          context: context,
          relative_url: context.entity.relation_download_url_path(relation, context.extra[:batch_number])
        )
      end

      new(tmpdir: tmpdir, filename: filename, file_download_strategy: file_download_strategy)
    end

    def initialize(tmpdir:, filename:, file_download_strategy:)
      @tmpdir = tmpdir
      @filename = filename
      @file_download_strategy = file_download_strategy
    end

    def execute
      validate_tmpdir
      file_download_strategy.validate!

      file_download_strategy.download_file(filepath)

      filepath
    end

    private

    attr_reader :file_download_strategy, :tmpdir, :filename

    def validate_tmpdir
      Gitlab::PathTraversal.check_allowed_absolute_path!(tmpdir, [Dir.tmpdir])
    end

    def filepath
      @filepath ||= File.join(tmpdir, filename)
    end
  end
end
