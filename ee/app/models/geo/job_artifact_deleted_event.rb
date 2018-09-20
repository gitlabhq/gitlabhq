module Geo
  class JobArtifactDeletedEvent < ActiveRecord::Base
    include Geo::Model
    include Geo::Eventable

    belongs_to :job_artifact, class_name: 'Ci::JobArtifact'

    validates :job_artifact, :file_path, presence: true
  end
end
