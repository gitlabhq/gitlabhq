# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module API
      # Checks that in API definitions each param has a desc block.
      # Hidden params accepted and linter van be disabled
      # ie. requires :invisible, type: String, documentation: { hidden: true }
      #
      # @example
      #
      #   # bad
      #     params do
      #       requires :id, types: [String, Integer]
      #       optional :search, type: String
      #     end
      #
      #   # bad
      #     params do
      #       requires :current_file, type: Hash do
      #         requires :file_name, type: String, limit: 255, desc: 'The name of the current file'
      #         requires :content_above_cursor, type: String, limit: MAX_CONTENT_SIZE, desc: 'The content above cursor'
      #         optional :content_below_cursor, type: String, limit: MAX_CONTENT_SIZE, desc: 'The content below cursor'
      #       end
      #     end
      #
      #   # good
      #     params do
      #       requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project owned by a user'
      #       optional :search,
      #         type: String,
      #         desc: "Return list of things matching the search criteria. Must be at least 4 characters."
      #     end
      #
      #    # good
      #      params do
      #        requires :current_file, type: Hash, desc: "File information for actions" do
      #          requires :file_name, type: String, limit: 255, desc: 'The name of the current file'
      #          requires :content_above_cursor, type: String, limit: MAX_CONTENT_SIZE, desc: 'The content above cursor'
      #          optional :content_below_cursor, type: String, limit: MAX_CONTENT_SIZE, desc: 'The content below cursor'
      #        end
      #      end
      #
      class ParameterDescription < RuboCop::Cop::Base
        include CodeReuseHelpers

        MSG = 'API params must include a desc.'
        RESTRICT_ON_SEND = %i[requires optional].freeze

        # @!method has_desc?(node)
        def_node_matcher :has_desc?, <<~PATTERN
          (send _
            ...
            (hash <(pair (sym :desc) {(str _) (dstr ...)}) ...>)
          )
        PATTERN

        def on_send(node)
          return if has_desc?(node)

          add_offense(node)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
