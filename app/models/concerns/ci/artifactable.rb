# frozen_string_literal: true

module Ci
  module Artifactable
    extend ActiveSupport::Concern

    include ObjectStorable

    STORE_COLUMN = :file_store
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

      scope :expired_before, -> (timestamp) { where(arel_table[:expire_at].lt(timestamp)) }
      scope :expired, -> (limit) { expired_before(Time.current).limit(limit) }
      scope :project_id_in, ->(ids) { where(project_id: ids) }
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

Ci::Artifactable.prepend_mod
