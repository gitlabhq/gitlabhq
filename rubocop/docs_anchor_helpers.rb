# frozen_string_literal: true

require 'digest'

module RuboCop
  # Resolves files under doc/ and the heading anchors inside them, for the cops that check
  # links into the documentation.
  module DocsAnchorHelpers
    HEADER_ID = /(?:[ \t]+\{\#([A-Za-z][\w:-]*)\})?/
    ATX_HEADER_MATCH = /^(\#{1,6})(.+?(?:\\#)?)\s*?#*#{HEADER_ID}\s*?\n/
    NON_WORD_RE = /[^\p{Word}\- \t]/
    MARKDOWN_LINK_TEXT = /\[(?<link_text>[^\]]+)\]\((?<link_url>[^)]+)\)/

    def self.included(base)
      base.singleton_class.attr_accessor(:anchors_by_docs_file)
      base.anchors_by_docs_file = {}
    end

    def external_dependency_checksum
      @external_dependency_checksum ||=
        begin
          mds = Dir["doc/**/*.md"]
          digest = Digest::SHA512.new
          mds.each { |md| digest.update(doc_signature(md)) }
          digest.hexdigest
        end
    end

    private

    # A `\0` delimited signature for a doc file, capturing only what affects
    # anchor resolution: its path and its heading anchors
    # (prose is excluded so prose-only edits don't invalidate the cache).
    def doc_signature(file)
      [file, *get_anchors_in_markdown(file)].join("\0") << "\0"
    end

    def docs_file_exists?(docs_file_path)
      return true if File.exist?(docs_file_path)

      false
    end

    def anchor_exists_in_markdown?(anchor, docs_file_path)
      return true unless anchor

      anchors = get_anchors_in_markdown(docs_file_path)

      return true if anchors.include?(anchor)

      false
    end

    # The logic in here replicates our custom Kramdown header parser at https://gitlab.com/gitlab-org/ruby/gems/gitlab_kramdown/-/blob/bbc5ac439a2e6af60cbcce9a157283b2c5b59b38/lib/gitlab_kramdown/parser/header.rb.
    # The logic is documented here: https://docs.gitlab.com/user/markdown/#heading-anchors.
    # There is a special undocumented syntax that makes it possible to set custom IDs, eg:
    # ```md
    # ### My heading {#my-custom-id}
    # ```
    # This would result in a `my-custom-id` anchor instead of `my-heading`.
    # We are also handling this special syntax in here.
    def get_anchors_in_markdown(docs_file_path)
      self.class.anchors_by_docs_file.fetch(docs_file_path) do
        docs_content = File.read(docs_file_path)
        headers = docs_content.scan(ATX_HEADER_MATCH)
        counters = Hash.new(0)

        self.class.anchors_by_docs_file[docs_file_path] = headers.map do |header|
          _level, text, id = header

          id || generate_anchor(text, counters)
        end
      end
    end

    def generate_anchor(text, counters)
      anchor = text.to_s.strip.downcase
      anchor.gsub!(MARKDOWN_LINK_TEXT) { |s| MARKDOWN_LINK_TEXT.match(s)[:link_text].gsub(NON_WORD_RE, '') }
      anchor.gsub!(NON_WORD_RE, '')
      anchor.tr!(" \t", '-')
      anchor << (counters[anchor] > 0 ? "-#{counters[anchor]}" : '')
      counters[anchor] += 1
      anchor
    end
  end
end
