module Ci
  class BuildEnvironmentDeployment
    belongs_to :build, class_name: 'Ci::Build'
    belongs_to :environment, class_name: 'Environment'

    enum :action {
      start: 1,
      stop: 2
    }

    validates :build, presence: true
    validates :environment, presence: true

    delegate :name, to: :environment, prefix: true

    def deployment
      self.build.last_deployment
    end

    def outdated?
      build.success? && !deployment&.latest?
    end
  end
end
