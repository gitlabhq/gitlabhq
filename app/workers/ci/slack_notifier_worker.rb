module Ci
  class SlackNotifierWorker
    include Sidekiq::Worker

    def perform(webhook_url, message, options={})
      notifier = Slack::Notifier.new(webhook_url)
      notifier.ping(message, options)
    end
  end
end
