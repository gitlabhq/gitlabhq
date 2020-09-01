# frozen_string_literal: true

module Ci
  module Artifactable
    extend ActiveSupport::Concern

    NotSupportedAdapterError = Class.new(StandardError)

    FILE_FORMAT_ADAPTERS = {
      gzip: Gitlab::Ci::Build::Artifacts::Adapters::GzipStream,
      raw: Gitlab::Ci::Build::Artifacts::Adapters::RawStream
    }.freeze

    included do
      enum file_format: {
        raw: 1,
        zip: 2,
        gzip: 3
      }, _suffix: true

      scope :expired, -> (limit) { where('expire_at < ?', Time.current).limit(limit) }
    end

    def each_blob(&blk)
      unless file_format_adapter_class
        raise NotSupportedAdapterError, 'This file format requires a dedicated adapter'
      end

      file.open do |stream|
        file_format_adapter_class.new(stream).each_blob(&blk)
      end
    end

    private

    def file_format_adapter_class
      FILE_FORMAT_ADAPTERS[file_format.to_sym]
    end
  end
end
