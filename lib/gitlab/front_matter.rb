# frozen_string_literal: true

module Gitlab
  module FrontMatter
    DELIM_LANG = {
      '---' => 'yaml',
      '+++' => 'toml',
      ';;;' => 'json'
    }.freeze

    DELIM_UNTRUSTED = "(?:#{Gitlab::FrontMatter::DELIM_LANG.keys.map { |x| RE2::Regexp.escape(x) }.join('|')})".freeze

    # Original pattern:
    #   \A(?<encoding>[^\r\n]*coding:[^\r\n]*\R)? # optional encoding line
    #   (?<before>\s*)
    #   ^(?<delim>#{DELIM})[ \t]*(?<lang>\S*)\R # opening front matter marker (optional language specifier)
    #   (?<front_matter>.*?)                    # front matter block content (not greedy)
    #   ^(\k<delim> | \.{3})                    # closing front matter marker
    #   [^\S\r\n]*(\R|\z)
    # rubocop:disable Style/StringConcatenation
    # rubocop:disable Style/LineEndConcatenation
    PATTERN_UNTRUSTED =
      # optional encoding line
      "\\A(?P<encoding>[^\\r\\n]*coding:[^\\r\\n]*#{::Gitlab::UntrustedRegexp::BACKSLASH_R})?" +
      '(?P<before>\s*)' +

      # opening front matter marker (optional language specifier)
      "^(?P<delim>#{DELIM_UNTRUSTED})[ \\t]*(?P<lang>\\S*)#{::Gitlab::UntrustedRegexp::BACKSLASH_R}" +

      # front matter block content (not greedy)
      '(?P<front_matter>(?:\n|.)*?)' +

      # closing front matter marker
      "^((?P<delim_closing>#{DELIM_UNTRUSTED})|\\.{3})" +
      "[^\\S\\r\\n]*(#{::Gitlab::UntrustedRegexp::BACKSLASH_R}|\\z)"
    # rubocop:enable Style/LineEndConcatenation
    # rubocop:enable Style/StringConcatenation

    PATTERN_UNTRUSTED_REGEX =
      Gitlab::UntrustedRegexp.new(PATTERN_UNTRUSTED, multiline: true).freeze
  end
end
