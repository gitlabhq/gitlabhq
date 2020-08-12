# frozen_string_literal: true

module Ci
  module Artifactable
    extend ActiveSupport::Concern

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
    end
  end
end
