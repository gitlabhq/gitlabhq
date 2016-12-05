module Ci
  class Stage < ActiveRecord::Base
    include ActiveModel::Model

    attr_reader :pipeline, :name

    def initialize(pipeline, name: name, status: status = nil)
      @pipeline, @name, @status = pipeline, name, status
    end

    def status
      @status ||= statuses.latest.status
    end

    def statuses
      pipeline.statuses.where(stage: stage)
    end

    def builds
      pipeline.builds.where(stage: stage)
    end
  end
end
