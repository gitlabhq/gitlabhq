module Geo
  class NotifyNodesService < BaseNotify
    def initialize
      @wiki_queue = Gitlab::Geo::UpdateQueue.new('updated_wikis')
    end

    def execute
      process(@wiki_queue, :notify_wikis_url)
    end

    private

    def process(queue, notify_url_method)
      return if queue.empty?

      projects = queue.fetch_batched_data
      content = { projects: projects }.to_json

      ::Gitlab::Geo.secondary_nodes.each do |node|
        next unless node.enabled?

        notify_url = node.__send__(notify_url_method.to_sym) # rubocop:disable GitlabSecurity/PublicSend
        success, details = notify(notify_url, content)

        unless success
          Gitlab::Geo::Logger.error(
            class: self.class.name,
            message: "GitLab failed to notify",
            error: details,
            node_url: node.url,
            notify_url: notify_url)
          queue.store_batched_data(projects)
        end
      end
    end
  end
end
