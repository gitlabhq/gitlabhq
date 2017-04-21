require 'slack-notifier'

module ChatMessage
  class BaseMessage
    attr_reader :markdown
    attr_reader :user_name
    attr_reader :user_avatar
    attr_reader :project_name
    attr_reader :project_url

    def initialize(params)
      @markdown = params[:markdown] || false
      @project_name = params.dig(:project, :path_with_namespace) || params[:project_name]
      @project_url = params.dig(:project, :web_url) || params[:project_url]
      @user_name = params.dig(:user, :username) || params[:user_name]
      @user_avatar = params.dig(:user, :avatar_url) || params[:user_avatar]
    end

    def pretext
      return message if markdown

      format(message)
    end

    def fallback
    end

    def attachments
      raise NotImplementedError
    end

    def activity
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
