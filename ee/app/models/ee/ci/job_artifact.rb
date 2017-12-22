module EE
  # CI::JobArtifact EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Ci::JobArtifact` model
  module Ci::JobArtifact
    extend ActiveSupport::Concern

    prepended do
      scope :with_files_stored_locally, -> { where(file_store: [nil, JobArtifactUploader::LOCAL_STORE]) }
    end
  end
end
