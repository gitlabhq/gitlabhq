require 'slack-notifier'

class SlackService
  class BaseMessage
    def initialize(params)
      raise NotImplementedError
    end

    def pretext
      format(message)
    end

    def fallback
    end

    def attachments
      raise NotImplementedError
    end

    private

    def message
      raise NotImplementedError
    end

    def format(string)
      Slack::Notifier::LinkFormatter.format(string)
    end

    def attachment_color
      '#345'
    end
  end
end
