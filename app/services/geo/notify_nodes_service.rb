module Geo
  class NotifyNodesService
    include HTTParty

    # HTTParty timeout
    default_timeout Gitlab.config.gitlab.webhook_timeout

    def initialize
      @proj_queue = Gitlab::Geo::UpdateQueue.new('updated_projects')
      @wiki_queue = Gitlab::Geo::UpdateQueue.new('updated_wikis')
    end

    def execute
      process(@proj_queue, :notify_projects_url)
      process(@wiki_queue, :notify_wikis_url)
    end

    private

    def process(queue, notify_url_method)
      return if queue.empty?
      projects = queue.fetch_batched_data

      ::Gitlab::Geo.secondary_nodes.each do |node|
        notify_url = node.send(notify_url_method.to_sym)
        success, message = notify(notify_url, projects)
        unless success
          Rails.logger.error("GitLab failed to notify #{node.url} to #{notify_url} : #{message}")
          queue.store_batched_data(projects)
        end
      end
    end

    def notify(notify_url, projects)
      response = self.class.post(notify_url,
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
