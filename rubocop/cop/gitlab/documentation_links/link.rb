# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      module DocumentationLinks
        # Ensure that `help_page_path` links to existing documentation and that the paths
        # include the .md extension.
        #
        # @example
        #
        #   # bad
        #   help_page_path('this/file/does/not/exist.md')
        #   help_page_path('this/file/exists.md#but-not-this-anchor')
        #   help_page_path('this/file/exists.md', anchor: 'but-not-this-anchor')
        #   help_page_path(path_as_a_variable)
        #   help_page_path('this/file/exists.md', anchor: anchor_as_a_variable)
        #   help_page_path('this/file/exists')
        #   help_page_path('this/file/exists.html')

        #   # good
        #   help_page_path('this/file/exists.md')
        #   help_page_path('this/file/exists.md#and-this-anchor-too')
        #   help_page_path('this/file/exists.md', anchor: 'and-this-anchor-too')
        class Link < RuboCop::Cop::Base
          extend RuboCop::Cop::AutoCorrector

          MSG_PATH_NOT_A_STRING = '`help_page_path`\'s first argument must be passed as a string ' \
            'so that Rubocop can ensure the linked file exists.'
          MSG_PATH_NEEDS_MD_EXTENSION = 'Add .md extension to the link: %{path}.'
          MSG_FILE_NOT_FOUND = 'This file does not exist: `%{file_path}`.'
          MSG_ANCHOR_NOT_A_STRING = '`help_page_path`\'s `anchor` argument must be passed as a string ' \
            'so that Rubocop can ensure it exists within the linked file.'
          MSG_ANCHOR_NOT_FOUND = 'The anchor `#%{anchor}` was not found in `%{file_path}`.'

          HEADER_ID = /(?:[ \t]+\{\#([A-Za-z][\w:-]*)\})?/
          ATX_HEADER_MATCH = /^(\#{1,6})(.+?(?:\\#)?)\s*?#*#{HEADER_ID}\s*?\n/
          NON_WORD_RE = /[^\p{Word}\- \t]/
          MARKDOWN_LINK_TEXT = /\[(?<link_text>[^\]]+)\]\((?<link_url>[^)]+)\)/

          class << self
            attr_accessor :anchors_by_docs_file
          end
          self.anchors_by_docs_file = {}

          def_node_matcher :help_page_path?, <<~PATTERN
            (send _ {:help_page_url :help_page_path} $...)
          PATTERN
          RESTRICT_ON_SEND = %i[help_page_url help_page_path].to_set.freeze

          def_node_matcher :anchor_param, <<~PATTERN
            (send nil? %RESTRICT_ON_SEND
              _
              (hash
                <(pair (sym :anchor) $_) ...>
              )
            )
          PATTERN

          def on_send(node)
            return unless valid_argument_count?(node)

            path = check_path_argument(node)
            return unless path

            path_without_anchor = check_md_extension(node, path)

            docs_file_path = File.join('doc', path_without_anchor)

            return unless check_file_exists(node, docs_file_path)

            return unless has_anchor?(node)

            anchor = get_anchor(node)

            return unless check_anchor_type(node, anchor)

            check_anchor_exists(node, anchor, docs_file_path)
          end

          def external_dependency_checksum
            @external_dependency_checksum ||=
              begin
                mds = Dir["doc/**/*.md"]
                digest = Digest::SHA512.new
                mds.each { |md| digest.file(md) }
                digest.hexdigest
              end
          end

          private

          def check_path_argument(node)
            unless first_argument_is_string?(node)
              add_offense(node, message: MSG_PATH_NOT_A_STRING)
              return
            end

            node.arguments.first.value
          end

          def check_md_extension(node, path)
            path_without_anchor = path.gsub(%r{#.*$}, '')

            unless path_has_md_extension?(path_without_anchor)
              add_offense(node, message: format(MSG_PATH_NEEDS_MD_EXTENSION, path: path)) do |corrector|
                extension_pattern = /(\.[\da-zA-Z]+)?/
                path_without_extension = path_without_anchor.gsub(/#{extension_pattern}$/, '')
                arg_with_md_extension = path.gsub(/#{path_without_extension}#{extension_pattern}(\#.+)?$/,
                  "#{path_without_extension}.md\\2")
                corrector.replace(node.arguments.first.source_range, "'#{arg_with_md_extension}'")
              end
              path_without_anchor += ".md"
            end

            path_without_anchor
          end

          def check_file_exists(node, docs_file_path)
            unless docs_file_exists?(docs_file_path)
              add_offense(node, message: format(MSG_FILE_NOT_FOUND, file_path: docs_file_path))
              return false
            end

            true
          end

          def check_anchor_type(node, anchor)
            unless anchor.instance_of? String
              add_offense(node, message: MSG_ANCHOR_NOT_A_STRING)
              return false
            end

            true
          end

          def check_anchor_exists(node, anchor, docs_file_path)
            return true if anchor_exists_in_markdown?(anchor, docs_file_path)

            add_offense(node, message: format(MSG_ANCHOR_NOT_FOUND, anchor: anchor, file_path: docs_file_path))

            false
          end

          def valid_argument_count?(node)
            node.arguments.count > 0
          end

          def first_argument_is_string?(node)
            return true if node.arguments.first.str_type?

            false
          end

          def path_has_md_extension?(path_without_anchor)
            return true if path_without_anchor.end_with?('.md')

            false
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

          def has_anchor?(node)
            return !node.arguments.first.value[/#(.+)$/, 1].nil? if node.arguments.length == 1

            anchor_param(node) != nil
          end

          def get_anchor(node)
            return node.arguments.first.value[/#(.+)$/, 1] if node.arguments.length == 1

            anchor_node = anchor_param(node)
            return unless anchor_node

            anchor_node.value if anchor_node.str_type?
          end

          # This methods extracts anchors from a Markdown file. The logic in here replicates our
          # custom Kramdown header parser at https://gitlab.com/gitlab-org/ruby/gems/gitlab_kramdown/-/blob/bbc5ac439a2e6af60cbcce9a157283b2c5b59b38/lib/gitlab_kramdown/parser/header.rb.
          # The logic is documented here: https://docs.gitlab.com/ee/user/markdown.html#heading-ids-and-links.
          # There a special undocumnented syntax that makes it possible to set custom IDs, eg:
          # ```md
          # ### My heading {#my-custom-id}
          # ```
          # This would result in a `my-custom-id` anchor instead of `my-heading`. We are also handling
          # this special syntax in here.
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
    end
  end
end
