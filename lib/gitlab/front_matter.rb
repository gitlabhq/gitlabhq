# frozen_string_literal: true

module Gitlab
  module FrontMatter
    DELIM_LANG = {
      '---' => 'yaml',
      '+++' => 'toml',
      ';;;' => 'json'
    }.freeze

    DELIM = Regexp.union(DELIM_LANG.keys)

    PATTERN = %r{
      \A(?:[^\r\n]*coding:[^\r\n]*\R)?        # optional encoding line
      \s*
      ^(?<delim>#{DELIM})[ \t]*(?<lang>\S*)\R # opening front matter marker (optional language specifier)
      (?<front_matter>.*?)                    # front matter block content (not greedy)
      ^(\k<delim> | \.{3})                    # closing front matter marker
      \s*
    }mx.freeze
  end
end
