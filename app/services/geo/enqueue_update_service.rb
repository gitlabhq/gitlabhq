module Geo
  class EnqueueUpdateService < Geo::BaseService
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
