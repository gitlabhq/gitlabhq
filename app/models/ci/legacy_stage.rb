# frozen_string_literal: true

module Ci
  # Currently this is artificial object, constructed dynamically
  # We should migrate this object to actual database record in the future
  class LegacyStage
    include StaticModel
    include Presentable

    attr_reader :pipeline, :name

    delegate :project, to: :pipeline

    def initialize(pipeline, name:, status: nil, warnings: nil)
      @pipeline = pipeline
      @name = name
      @status = status
      # support ints and booleans
      @has_warnings = ActiveRecord::Type::Boolean.new.cast(warnings)
    end

    def groups
      @groups ||= Ci::Group.fabricate(project, self)
    end

    def to_param
      name
    end

    def statuses_count
      @statuses_count ||= statuses.count
    end

    def status
      @status ||= statuses.latest.composite_status(project: project)
    end

    def detailed_status(current_user)
      Gitlab::Ci::Status::Stage::Factory
        .new(self, current_user)
        .fabricate!
    end

    def latest_statuses
      statuses.ordered.latest
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
      # lazilly calculate the warnings
      if @has_warnings.nil?
        @has_warnings = statuses.latest.failed_but_allowed.any?
      end

      @has_warnings
    end

    def manual_playable?
      %[manual scheduled skipped].include?(status.to_s)
    end
  end
end
