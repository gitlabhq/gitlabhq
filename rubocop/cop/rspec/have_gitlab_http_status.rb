# frozen_string_literal: true

require 'rack/utils'
require 'rubocop-rspec'

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
      # expect(response.status).to eq(200)
      # expect(response.status).not_to eq(200)
      #
      # # good
      # expect(response).to have_gitlab_http_status(:ok)
      # expect(response).not_to have_gitlab_http_status(:ok)
      #
      class HaveGitlabHttpStatus < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        CODE_TO_SYMBOL = Rack::Utils::SYMBOL_TO_STATUS_CODE.invert

        MSG_MATCHER_NAME =
          'Prefer `have_gitlab_http_status` over `have_http_status`.'

        MSG_NUMERIC_STATUS =
          'Prefer named HTTP status `%{name}` over ' \
          'its numeric representation `%{code}`.'

        MSG_RESPONSE_STATUS =
          'Prefer `have_gitlab_http_status` matcher over ' \
          '`response.status`.'

        MSG_UNKNOWN_STATUS = 'HTTP status `%{code}` is unknown. ' \
                             'Please provide a valid one or disable this cop.'

        MSG_DOCS_LINK = 'https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#have_gitlab_http_status'

        REPLACEMENT = 'have_gitlab_http_status(%{arg})'

        REPLACEMENT_RESPONSE_STATUS =
          'expect(response).%{expectation} have_gitlab_http_status(%{arg})'

        def_node_matcher :have_http_status?, <<~PATTERN
          (send nil?
              { :have_http_status :have_gitlab_http_status }
              _
          )
        PATTERN

        def_node_matcher :response_status_eq?, <<~PATTERN
          (send
            (send nil? :expect
              (send
                (send nil? :response) :status)) ${ :to :not_to }
            (send nil? :eq
              (int $_)))
        PATTERN

        def on_send(node)
          offense_for_matcher(node) || offense_for_response_status(node)
        end

        private

        def offense_for_matcher(node)
          return unless have_http_status?(node)

          offenses = [
            offense_for_name(node),
            offense_for_status(node)
          ].compact

          return if offenses.empty?

          add_offense(node, message: message_for(*offenses), &corrector(node))
        end

        def offense_for_response_status(node)
          return unless response_status_eq?(node)

          add_offense(node, message: message_for(MSG_RESPONSE_STATUS), &corrector(node))
        end

        def corrector(node)
          ->(corrector) do
            replacement = replace_matcher(node) || replace_response_status(node)
            corrector.replace(node.source_range, replacement) if node.source_range.source != replacement
          end
        end

        def replace_matcher(node)
          return unless have_http_status?(node)

          code = extract_numeric_code(node)
          arg = code_to_symbol(code) || argument(node).source

          format(REPLACEMENT, arg: arg)
        end

        def replace_response_status(node)
          expectation, code = response_status_eq?(node)
          return unless code

          arg = code_to_symbol(code)
          format(REPLACEMENT_RESPONSE_STATUS, expectation: expectation, arg: arg)
        end

        def offense_for_name(node)
          return if method_name(node) == :have_gitlab_http_status

          MSG_MATCHER_NAME
        end

        def offense_for_status(node)
          code = extract_numeric_code(node)
          return unless code

          symbol = code_to_symbol(code)
          return format(MSG_UNKNOWN_STATUS, code: code) unless symbol

          format(MSG_NUMERIC_STATUS, name: symbol, code: code)
        end

        def message_for(*offenses)
          (offenses + [MSG_DOCS_LINK]).join(' ')
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
