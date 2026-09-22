# frozen_string_literal: true

require_relative '../../../docs_anchor_helpers'

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

          include DocsAnchorHelpers

          MSG_PATH_NOT_A_STRING = '`help_page_path`\'s first argument must be passed as a string ' \
            'so that Rubocop can ensure the linked file exists.'
          MSG_PATH_NEEDS_MD_EXTENSION = 'Add .md extension to the link: %{path}.'
          MSG_FILE_NOT_FOUND = 'This file does not exist: `%{file_path}`.'
          MSG_ANCHOR_NOT_A_STRING = '`help_page_path`\'s `anchor` argument must be passed as a string ' \
            'so that Rubocop can ensure it exists within the linked file.'
          MSG_ANCHOR_NOT_FOUND = 'The anchor `#%{anchor}` was not found in `%{file_path}`.'

          # @!method help_page_path?(node)
          def_node_matcher :help_page_path?, <<~PATTERN
            (send _ {:help_page_url :help_page_path} $...)
          PATTERN
          RESTRICT_ON_SEND = %i[help_page_url help_page_path].to_set.freeze

          # @!method anchor_param(node)
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

          private

          def check_path_argument(node)
            unless first_argument_is_string?(node)
              add_offense(node, message: MSG_PATH_NOT_A_STRING)
              return
            end

            node.first_argument.value
          end

          def check_md_extension(node, path)
            path_without_anchor = path.gsub(%r{#.*$}, '')

            unless path_has_md_extension?(path_without_anchor)
              add_offense(node, message: format(MSG_PATH_NEEDS_MD_EXTENSION, path: path)) do |corrector|
                extension_pattern = /(\.[\da-zA-Z]+)?/
                path_without_extension = path_without_anchor.gsub(/#{extension_pattern}$/, '')
                arg_with_md_extension = path.gsub(/#{path_without_extension}#{extension_pattern}(\#.+)?$/,
                  "#{path_without_extension}.md\\2")
                corrector.replace(node.first_argument, "'#{arg_with_md_extension}'")
              end
              path_without_anchor += ".md"
            end

            path_without_anchor
          end

          def check_file_exists(node, docs_file_path)
            unless docs_file_exists?(docs_file_path)
              add_offense(node.first_argument,
                message: format(MSG_FILE_NOT_FOUND, file_path: docs_file_path))
              return false
            end

            true
          end

          def check_anchor_type(node, anchor)
            unless anchor.instance_of? String
              loc = anchor_param(node)&.source_range || node.first_argument.source_range
              add_offense(loc, message: MSG_ANCHOR_NOT_A_STRING)
              return false
            end

            true
          end

          def check_anchor_exists(node, anchor, docs_file_path)
            return true if anchor_exists_in_markdown?(anchor, docs_file_path)

            loc = anchor_param(node)&.source_range || node.first_argument.source_range

            add_offense(loc, message: format(MSG_ANCHOR_NOT_FOUND, anchor: anchor, file_path: docs_file_path))

            false
          end

          def valid_argument_count?(node)
            node.arguments.count > 0
          end

          def first_argument_is_string?(node)
            return true if node.first_argument.str_type?

            false
          end

          def path_has_md_extension?(path_without_anchor)
            return true if path_without_anchor.end_with?('.md')

            false
          end

          def has_anchor?(node)
            return !node.first_argument.value[/#(.+)$/, 1].nil? if node.arguments.length == 1

            anchor_param(node) != nil
          end

          def get_anchor(node)
            return node.first_argument.value[/#(.+)$/, 1] if node.arguments.length == 1

            anchor_node = anchor_param(node)
            return unless anchor_node

            anchor_node.value if anchor_node.str_type?
          end
        end
      end
    end
  end
end
