require 'slack-notifier'

module SlackMessages
  class SlackBaseMessage
    def initialize(params)
      raise NotImplementedError
    end

    def pretext
      format(message)
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
