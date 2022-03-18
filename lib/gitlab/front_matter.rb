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
      \A(?<encoding>[^\r\n]*coding:[^\r\n]*\R)? # optional encoding line
      (?<before>\s*)
      ^(?<delim>#{DELIM})[ \t]*(?<lang>\S*)\R # opening front matter marker (optional language specifier)
      (?<front_matter>.*?)                    # front matter block content (not greedy)
      ^(\k<delim> | \.{3})                    # closing front matter marker
      [^\S\r\n]*(\R|\z)
    }mx.freeze
  end
end
