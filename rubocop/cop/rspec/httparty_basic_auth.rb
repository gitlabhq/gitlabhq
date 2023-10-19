# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module RSpec
      # This cop checks for invalid credentials passed to HTTParty
      #
      # @example
      #
      #   # bad
      #   HTTParty.get(url, basic_auth: { user: 'foo' })
      #
      #   # good
      #   HTTParty.get(url, basic_auth: { username: 'foo' })
      class HTTPartyBasicAuth < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MESSAGE = "`basic_auth: { user: ... }` does not work - replace `user:` with `username:`"

        RESTRICT_ON_SEND = %i[get put post delete].freeze

        def_node_matcher :httparty_basic_auth?, <<~PATTERN
          (send
            (const _ :HTTParty)
            {#{RESTRICT_ON_SEND.map(&:inspect).join(' ')}}
            <(hash
              <(pair
                (sym :basic_auth)
                (hash
                  <(pair $(sym :user) _) ...>
                )
              ) ...>
            ) ...>
          )
        PATTERN

        def on_send(node)
          return unless m = httparty_basic_auth?(node)

          add_offense(m, message: MESSAGE) do |corrector|
            corrector.replace(m, 'username')
          end
        end
      end
    end
  end
end
