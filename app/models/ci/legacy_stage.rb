module Ci
  # Currently this is artificial object, constructed dynamically
  # We should migrate this object to actual database record in the future
  class LegacyStage
    include StaticModel

    attr_reader :pipeline, :name

    delegate :project, to: :pipeline

    def initialize(pipeline, name:, status: nil, warnings: nil)
      @pipeline = pipeline
      @name = name
      @status = status
      @warnings = warnings
    end

    def groups
      @groups ||= Ci::Group.fabricate(self)
    end

    def to_param
      name
    end

    def statuses_count
      @statuses_count ||= statuses.count
    end

    def status
      @status ||= statuses.latest.status
    end

    def detailed_status(current_user)
      Gitlab::Ci::Status::Stage::Factory
        .new(self, current_user)
        .fabricate!
    end

    def statuses
      @statuses ||= pipeline.statuses.where(stage: name)
    end

    def builds
      @builds ||= pipeline.builds.where(stage: name)
    end

    def success?
      status.to_s == 'success'
    end

    def has_warnings?
      if @warnings.is_a?(Integer)
        @warnings > 0
      else
        statuses.latest.failed_but_allowed.any?
      end
    end
  end
end
