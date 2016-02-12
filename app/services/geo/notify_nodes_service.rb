require_relative 'base_service'

module Geo
  class NotifyNodesService < BaseService
    include HTTParty
    BATCH_SIZE = 250

    # HTTParty timeout
    default_timeout Gitlab.config.gitlab.webhook_timeout

    def initialize
      @redis = redis_connection
    end

    def execute
      queue_size = @redis.llen('updated_projects')
      return if queue_size == 0

      if queue_size > BATCH_SIZE
        batch_size = BATCH_SIZE
      else
        batch_size = queue_size
      end

      projects = []
      @redis.multi do |redis|
        projects = redis.lrange(0, batch_size-1)
        redis.ltrim(0, batch_size-1)
      end

      ::Gitlab::Geo.secondary_nodes.each do |node|
        notify_updated_projects(node, projects.value)
      end
    end

    private

    def notify_updated_projects(node, projects)
      self.post(node.notify_url,
                body: projects.to_json,
                headers: {
                  "Content-Type" => "application/json",
                  "X-Gitlab-Geo-Event" => "Update Repositories"
                })

      # TODO: Authentication
      [(response.code >= 200 && response.code < 300), ActionView::Base.full_sanitizer.sanitize(response.to_s)]
    end
  end
end
