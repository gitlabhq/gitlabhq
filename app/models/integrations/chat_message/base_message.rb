# frozen_string_literal: true

module Integrations
  module ChatMessage
    class BaseMessage
      RELATIVE_LINK_REGEX = Gitlab::UntrustedRegexp.new('!\[[^\]]*\]\((/uploads/[^\)]*)\)')

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

      # NOTE: Make sure to call `#strip_markup` on any untrusted user input that's added to the
      # `title`, `subtitle`, `text`, `fallback`, or `author_name` fields.
      def attachments
        raise NotImplementedError
      end

      # NOTE: Make sure to call `#strip_markup` on any untrusted user input that's added to the
      # `title`, `subtitle`, `text`, `fallback`, or `author_name` fields.
      def activity
        raise NotImplementedError
      end

      private

      # NOTE: Make sure to call `#strip_markup` on any untrusted user input that's added to the string.
      def message
        raise NotImplementedError
      end

      def format(string)
        ::Slack::Messenger::Util::LinkFormatter.format(format_relative_links(string))
      end

      def format_relative_links(string)
        return string unless RELATIVE_LINK_REGEX.match?(string)

        RELATIVE_LINK_REGEX.replace_gsub(string) do |match|
          "#{project_url}#{match[1]}"
        end
      end

      # Remove unsafe markup from user input, which can be used to hijack links in our own markup,
      # or insert new ones.
      #
      # This currently removes Markdown and Slack "mrkdwn" links (keeping the link label),
      # and all HTML markup (keeping the text nodes).
      # We can't just escape the markup characters, because each chat app handles this differently.
      #
      # See:
      # - https://api.slack.com/reference/surfaces/formatting#escaping
      # - https://gitlab.com/gitlab-org/slack-notifier#escaping
      def strip_markup(string)
        SlackMarkdownSanitizer.sanitize(string)
      end

      def attachment_color
        '#345'
      end

      def link(text, url)
        "[#{strip_markup(text)}](#{url})"
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
