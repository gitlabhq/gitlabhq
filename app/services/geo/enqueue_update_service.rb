require_relative 'base_service'

module Geo
  class EnqueueUpdateService < BaseService
    attr_reader :project

    def initialize(project)
      @project = project
      @redis = redis_connection
    end

    def execute
      @redis.rpush('updated_projects', @project.id)
    end
  end
end
