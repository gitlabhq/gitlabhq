# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module RSpec
      # Checks for invalid credentials passed to HTTParty
      #
      # HTTParty expects `username` instead of `user` in the basic_auth hash.
      # Using `user` will silently fail authentication.
      #
      # @example
      #
      #   # bad
      #   HTTParty.get(url, basic_auth: { user: 'admin' })
      #   HTTParty.post(url, basic_auth: { user: username })
      #   HTTParty.delete(endpoint, basic_auth: { user: ENV['API_USER'] })
      #   HTTParty.post(url, body: data.to_json, basic_auth: { user: username, password: password })
      #
      #   # good
      #   HTTParty.get(url, basic_auth: { username: 'admin' })
      #   HTTParty.post(url, basic_auth: { username: username })
      #   HTTParty.delete(endpoint, basic_auth: { username: ENV['API_USER'] })
      #   HTTParty.post(url, body: data.to_json, basic_auth: { username: username, password: password })
      class HTTPartyBasicAuth < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MESSAGE = "`basic_auth: { user: ... }` does not work - replace `user:` with `username:`"

        RESTRICT_ON_SEND = %i[get put post delete].freeze

        # @!method httparty_basic_auth?(node)
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
