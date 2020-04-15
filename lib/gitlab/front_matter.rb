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
      \A(?:[^\r\n]*coding:[^\r\n]*)?         # optional encoding line
      \s*
      ^(?<delim>#{DELIM})[ \t]*(?<lang>\S*)  # opening front matter marker (optional language specifier)
      \s*
      ^(?<front_matter>.*?)                  # front matter block content (not greedy)
      \s*
      ^(\k<delim> | \.{3})                   # closing front matter marker
      \s*
    }mx.freeze
  end
end
