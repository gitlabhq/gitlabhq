module Ci
  class JobArtifact < ActiveRecord::Base
    extend Gitlab::Ci::Model

    belongs_to :project
    belongs_to :job, class_name: "Ci::Build", foreign_key: :job_id

    before_save :set_size, if: :file_changed?
    after_commit :remove_file!, on: :destroy

    mount_uploader :file, JobArtifactUploader

    enum file_type: {
      archive: 1,
      metadata: 2
    }

    def self.artifacts_size_for(project)
      self.where(project: project).sum(:size)
    end

    def set_size
      self.size = file.size
    end
  end
end
