module Ci
  class RunnerBuild < ActiveRecord::Base
    extend Ci::Model

    belongs_to :build
    belongs_to :runner
    belongs_to :project
  end
end
