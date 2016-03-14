module Geo
  class NotifyNodesService < Geo::BaseService
    include HTTParty

    # HTTParty timeout
    default_timeout Gitlab.config.gitlab.webhook_timeout

    def execute
      return if @queue.empty?
      projects = @queue.fetch_batched_data

      ::Gitlab::Geo.secondary_nodes.each do |node|
        success, message = notify_updated_projects(node, projects)
        unless success
          Rails.logger.error("GitLab failed to notify #{node.url} : #{message}")
          @queue.store_batched_data(projects)
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

      [(response.code >= 200 && response.code < 300), ActionView::Base.full_sanitizer.sanitize(response.to_s)]
    rescue HTTParty::Error, Errno::ECONNREFUSED => e
      [false, ActionView::Base.full_sanitizer.sanitize(e.message)]
    end

    def private_token
      # TODO: should we ask admin user to be defined as part of configuration?
      @private_token ||= User.find_by(admin: true).authentication_token
    end
  end
end
