# frozen_string_literal: true

module Ci
  module Artifactable
    extend ActiveSupport::Concern

    include ObjectStorable
    include Gitlab::Ci::Artifacts::Logger

    STORE_COLUMN = :file_store
    NotSupportedAdapterError = Class.new(StandardError)

    FILE_FORMAT_ADAPTERS = {
      # While zip is a streamable file format, performing streaming
      # reads requires that each entry in the zip has certain headers
      # present at the front of the entry. These headers are OPTIONAL
      # according to the file format specification. GitLab Runner uses
      # Go's `archive/zip` to create zip archives, which does not include
      # these headers. Go maintainers have expressed that they don't intend
      # to support them: https://github.com/golang/go/issues/23301#issuecomment-363240781
      #
      # If you need GitLab to be able to read Artifactables, store them in
      # raw or gzip format instead of zip.
      gzip: Gitlab::Ci::Build::Artifacts::Adapters::GzipStream,
      raw: Gitlab::Ci::Build::Artifacts::Adapters::RawStream
    }.freeze

    JUNIT_MAX_BYTES = 100.megabytes

    included do
      enum file_format: {
        raw: 1,
        zip: 2,
        gzip: 3
      }, _suffix: true

      scope :expired_before, ->(timestamp) { where(arel_table[:expire_at].lt(timestamp)) }
      scope :expired, -> { expired_before(Time.current) }
      scope :project_id_in, ->(ids) { where(project_id: ids) }
    end

    def each_blob(&blk)
      unless file_format_adapter_class
        raise NotSupportedAdapterError, 'This file format requires a dedicated adapter'
      end

      ::Gitlab::Ci::Artifacts::DecompressedArtifactSizeValidator
        .new(file: file, file_format: file_format.to_sym, max_bytes: max_size_for_file_type).validate!

      log_artifacts_filesize(file.model)

      file.open do |stream|
        file_format_adapter_class.new(stream).each_blob(&blk)
      end
    end

    private

    def file_format_adapter_class
      FILE_FORMAT_ADAPTERS[file_format.to_sym]
    end

    def max_size_for_file_type
      if defined?(file_type) && file_type == 'junit'
        JUNIT_MAX_BYTES
      else
        Gitlab::Ci::Artifacts::DecompressedArtifactSizeValidator::DEFAULT_MAX_BYTES
      end
    end
  end
end
