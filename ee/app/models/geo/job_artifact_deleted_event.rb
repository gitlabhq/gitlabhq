module Geo
  class JobArtifactDeletedEvent < ActiveRecord::Base
    include Geo::Model

    belongs_to :job_artifact, class_name: 'Ci::JobArtifact'

    validates :job_artifact, presence: true
  end
end
