# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module Gitlab
      class ServiceResponse < ::RuboCop::Cop::Base
        include CodeReuseHelpers

        # This cop checks that ServiceResponse object is not used with the
        # deprecated attribute `http_status`.
        #
        # @example
        #
        #   # bad
        #   ServiceResponse.error(message: "...", http_status: :forbidden)
        #
        #   # good
        #   ServiceResponse.error(message: "...", reason: :insufficient_permissions)
        MSG = 'Use `reason` instead of the deprecated `http_status`: https://gitlab.com/gitlab-org/gitlab/-/issues/356036'

        RESTRICT_ON_SEND = %i[error success new].freeze
        METHOD_NAMES = RESTRICT_ON_SEND.map(&:inspect).join(' ').freeze

        def_node_matcher :service_response_with_http_status, <<~PATTERN
          (send
            (const {nil? cbase} :ServiceResponse)
            {#{METHOD_NAMES}}
            (hash <$(pair (sym :http_status) _) ...>)
          )
        PATTERN

        def on_send(node)
          pair = service_response_with_http_status(node)
          return unless pair

          add_offense(pair)
        end
      end
    end
  end
end
