# frozen_string_literal: true

# This class is being used to persist additional artifacts after a pipeline completes, which is a great place to cache a computed result in object storage

module Ci
  class PipelineArtifact < ApplicationRecord
    extend Gitlab::Ci::Model
    include UpdateProjectStatistics
    include Artifactable
    include FileStoreMounter
    include Presentable

    FILE_SIZE_LIMIT = 10.megabytes.freeze
    EXPIRATION_DATE = 1.week.freeze

    DEFAULT_FILE_NAMES = {
      code_coverage: 'code_coverage.json'
    }.freeze

    belongs_to :project, class_name: "Project", inverse_of: :pipeline_artifacts
    belongs_to :pipeline, class_name: "Ci::Pipeline", inverse_of: :pipeline_artifacts

    validates :pipeline, :project, :file_format, :file, presence: true
    validates :file_store, presence: true, inclusion: { in: ObjectStorage::SUPPORTED_STORES }
    validates :size, presence: true, numericality: { less_than_or_equal_to: FILE_SIZE_LIMIT }
    validates :file_type, presence: true

    mount_file_store_uploader Ci::PipelineArtifactUploader

    update_project_statistics project_statistics_name: :pipeline_artifacts_size

    enum file_type: {
      code_coverage: 1
    }

    def self.has_code_coverage?
      where(file_type: :code_coverage).exists?
    end

    def self.find_with_code_coverage
      find_by(file_type: :code_coverage)
    end

    def present
      super(presenter_class: "Ci::PipelineArtifacts::#{self.file_type.camelize}Presenter".constantize)
    end
  end
end
