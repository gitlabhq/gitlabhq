# frozen_string_literal: true

require 'rack/utils'

module RuboCop
  module Cop
    module RSpec
      # This cops checks for `have_http_status` usages in specs.
      # It also discourages the usage of numeric HTTP status codes in
      # `have_gitlab_http_status`.
      #
      # @example
      #
      # # bad
      # expect(response).to have_http_status(200)
      # expect(response).to have_http_status(:ok)
      # expect(response).to have_gitlab_http_status(200)
      #
      # # good
      # expect(response).to have_gitlab_http_status(:ok)
      #
      class HaveGitlabHttpStatus < RuboCop::Cop::Cop
        CODE_TO_SYMBOL = Rack::Utils::SYMBOL_TO_STATUS_CODE.invert

        MSG_MATCHER_NAME =
          'Use `have_gitlab_http_status` instead of `have_http_status`.'

        MSG_STATUS =
          'Prefer named HTTP status `%{name}` over ' \
          'its numeric representation `%{code}`.'

        MSG_UNKNOWN = 'HTTP status `%{code}` is unknown. ' \
          'Please provide a valid one or disable this cop.'

        MSG_DOCS_LINK = 'https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#have_gitlab_http_status'

        REPLACEMENT = 'have_gitlab_http_status(%{arg})'

        def_node_matcher :have_http_status?, <<~PATTERN
          (
            send nil?
              {
                :have_http_status
                :have_gitlab_http_status
              }
              _
          )
        PATTERN

        def on_send(node)
          return unless have_http_status?(node)

          offenses = [
            offense_for_name(node),
            offense_for_status(node)
          ].compact

          return if offenses.empty?

          add_offense(node, message: message_for(offenses))
        end

        def autocorrect(node)
          lambda do |corrector|
            corrector.replace(node.source_range, replacement(node))
          end
        end

        private

        def offense_for_name(node)
          return if method_name(node) == :have_gitlab_http_status

          MSG_MATCHER_NAME
        end

        def offense_for_status(node)
          code = extract_numeric_code(node)
          return unless code

          symbol = code_to_symbol(code)
          return format(MSG_UNKNOWN, code: code) unless symbol

          format(MSG_STATUS, name: symbol, code: code)
        end

        def message_for(offenses)
          (offenses + [MSG_DOCS_LINK]).join(' ')
        end

        def replacement(node)
          code = extract_numeric_code(node)
          arg = code_to_symbol(code) || argument(node).source

          format(REPLACEMENT, arg: arg)
        end

        def code_to_symbol(code)
          CODE_TO_SYMBOL[code]&.inspect
        end

        def extract_numeric_code(node)
          arg_node = argument(node)
          return unless arg_node&.type == :int

          arg_node.children[0]
        end

        def method_name(node)
          node.children[1]
        end

        def argument(node)
          node.children[2]
        end
      end
    end
  end
end
