module Ci
  class Artifact < ActiveRecord::Base
    extend Gitlab::Ci::Model

    belongs_to :project
    belongs_to :build, class_name: "Ci::Build", foreign_key: :ci_build_id

    before_save :set_size, if: :file_changed?

    mount_uploader :file, ArtifactUploader

    enum type: { archive: 0, metadata: 1 }

    # Allow us to use `type` as column name, without Rails thinking we're using
    # STI: https://stackoverflow.com/a/29663933
    def self.inheritance_column
      nil
    end

    def set_size
      self.size = file.exists? ? file.size : 0
    end
  end
end
