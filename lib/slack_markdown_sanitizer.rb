# frozen_string_literal: true

require 'slack-messenger'

module SlackMarkdownSanitizer
  # Markup characters which are used for links in HTML, Markdown,
  # and Slack "mrkdwn" syntax (`<http://example.com|Label>`).
  UNSAFE_MARKUP_CHARACTERS = '<>[]|'

  # Only Markdown links are converted into Slack links; HTML anchors stay plain text.
  LINK_FORMATS = %i[markdown].freeze

  def self.sanitize(string)
    string&.delete(UNSAFE_MARKUP_CHARACTERS)
  end

  def self.format_links(string)
    ::Slack::Messenger::Util::LinkFormatter.format(string, formats: LINK_FORMATS)
  end

  # Escapes the characters Slack parses as control characters so the text displays as written.
  def self.escape(string)
    return if string.nil?

    ::Slack::Messenger::Util::Escape.html(string)
  end

  def self.sanitize_slack_link(string)
    return string unless Gitlab::Regex.slack_link_regex.match?(string)

    Gitlab::Regex.slack_link_regex.replace_gsub(string) do |match|
      match.to_s.gsub("<", "&lt;").gsub(">", "&gt;")
    end
  end
end
