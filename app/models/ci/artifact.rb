module Ci
  class Artifact < ActiveRecord::Base
    belongs_to :build, class_name: "Ci::Build"
    belongs_to :project, class_name: "Ci::Build"

    enum type {
      archive: 0,
      metadata: 1,
      trace: 2
    }
  end
end
