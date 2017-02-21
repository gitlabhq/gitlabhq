require 'slack-notifier'

module ChatMessage
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

    def link(text, url)
      "[#{text}](#{url})"
    end
  end
end
