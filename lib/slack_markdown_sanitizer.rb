# frozen_string_literal: true

module SlackMarkdownSanitizer
  # Markup characters which are used for links in HTML, Markdown,
  # and Slack "mrkdwn" syntax (`<http://example.com|Label>`).
  UNSAFE_MARKUP_CHARACTERS = '<>[]|'

  def self.sanitize(string)
    string&.delete(UNSAFE_MARKUP_CHARACTERS)
  end

  def self.sanitize_slack_link(string)
    string.gsub(Gitlab::Regex.slack_link_regex) { |m| m.gsub("<", "&lt;").gsub(">", "&gt;") }
  end
end
