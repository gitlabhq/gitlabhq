module Geo
  class NotifyNodesService < Geo::BaseService
    include HTTParty
    BATCH_SIZE = 250
    QUEUE = 'updated_projects'

    # HTTParty timeout
    default_timeout Gitlab.config.gitlab.webhook_timeout

    def initialize
      @redis = redis_connection
    end

    def execute
      queue_size = @redis.llen(QUEUE)
      return if queue_size == 0

      if queue_size > BATCH_SIZE
        batch_size = BATCH_SIZE
      else
        batch_size = queue_size
      end

      projects = []
      @redis.multi do
        projects = @redis.lrange(QUEUE, 0, batch_size-1)
        @redis.ltrim(QUEUE, batch_size, -1)
      end

      ::Gitlab::Geo.secondary_nodes.each do |node|
        success, message = notify_updated_projects(node, projects.value)
        unless success
          Rails.logger.error("Gitlab Failed to notify #{node.url} : #{message}")
          reenqueue_projects(projects.value)
        end
      end
    end

    private

    def notify_updated_projects(node, projects)
      response = self.class.post(node.notify_url,
                                 body: { projects: projects }.to_json,
                                 headers: {
                                   'Content-Type' => 'application/json',
                                   'PRIVATE-TOKEN' => private_token
                                 })

      return [(response.code >= 200 && response.code < 300), ActionView::Base.full_sanitizer.sanitize(response.to_s)]
    rescue HTTParty::Error, Errno::ECONNREFUSED => e
      return [false, ActionView::Base.full_sanitizer.sanitize(e.message)]
    end

    def private_token
      # TODO: should we ask admin user to be defined as part of configuration?
      @private_token ||= User.find_by(admin: true).authentication_token
    end

    def reenqueue_projects(projects)
      @redis.pipelined do
        projects.each do |project|
          # enqueue again to the head of the queue
          @redis.lpush(QUEUE, project)
        end
      end
    end
  end
end
