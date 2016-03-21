module Geo
  class NotifyKeyChangeService < BaseNotify

    def initialize(key_id, key, action)
      @id = key_id
      @key = key
      @action = action
    end

    def execute
      key_change = { 'id' => @id, 'key' => @key, 'action' => @action }
      content = { key_change: key_change }.to_json

      ::Gitlab::Geo.secondary_nodes.each do |node|
        notify_url = node.notify_key_url
        success, message = notify(notify_url, content)

        unless success
          error_message = "GitLab failed to notify #{node.url} to #{notify_url} : #{message}"
          Rails.logger.error(error_message)
          fail error_message # we must throw exception here to re-schedule job execution.
        end
      end
    end
  end
end
