# frozen_string_literal: true

module Integrations
  module ChatMessage
    class BaseMessage
      RELATIVE_LINK_REGEX = %r{!\[[^\]]*\]\((/uploads/[^\)]*)\)}.freeze

      attr_reader :markdown
      attr_reader :user_full_name
      attr_reader :user_name
      attr_reader :user_avatar
      attr_reader :project_name
      attr_reader :project_url

      def initialize(params)
        @markdown = params[:markdown] || false
        @project_name = params[:project_name] || params.dig(:project, :path_with_namespace)
        @project_url = params.dig(:project, :web_url) || params[:project_url]
        @user_full_name = params.dig(:user, :name) || params[:user_full_name]
        @user_name = params.dig(:user, :username) || params[:user_name]
        @user_avatar = params.dig(:user, :avatar_url) || params[:user_avatar]
      end

      def user_combined_name
        if user_full_name.present?
          "#{user_full_name} (#{user_name})"
        else
          user_name
        end
      end

      def summary
        return message if markdown

        format(message)
      end

      def pretext
        summary
      end

      def fallback
        format(message)
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
        ::Slack::Messenger::Util::LinkFormatter.format(format_relative_links(string))
      end

      def format_relative_links(string)
        string.gsub(RELATIVE_LINK_REGEX, "#{project_url}\\1")
      end

      def attachment_color
        '#345'
      end

      def link(text, url)
        "[#{text}](#{url})"
      end

      def pretty_duration(seconds)
        parse_string =
          if duration < 1.hour
            '%M:%S'
          else
            '%H:%M:%S'
          end

        Time.at(seconds).utc.strftime(parse_string)
      end
    end
  end
end
