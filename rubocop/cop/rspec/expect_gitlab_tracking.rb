# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module RSpec
      # This cop checks for `expect(Gitlab::Tracking).to receive(:event)` usage in specs.
      # See /spec/support/helpers/snowplow_helpers.rb for details on the replacement.
      #
      # @example
      #
      # # bad
      # it 'expects a snowplow event' do
      #   expect(Gitlab::Tracking).to receive(:event).with("Category", "action", ...)
      # end
      #
      # # good
      # it 'expects a snowplow event', :snowplow do
      #   expect_snowplow_event(category: "Category", action: "action", ...)
      # end
      #
      # # bad
      # it 'does not expect a snowplow event' do
      #   expect(Gitlab::Tracking).not_to receive(:event)
      # end
      #
      # # good
      # it 'does not expect a snowplow event', :snowplow do
      #   expect_no_snowplow_event
      # end
      class ExpectGitlabTracking < RuboCop::Cop::Base
        MSG = 'Do not expect directly on `Gitlab::Tracking#event`, add the `snowplow` annotation and use ' \
              '`expect_snowplow_event` instead. ' \
              'See https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#test-snowplow-events'

        def_node_matcher :expect_gitlab_tracking?, <<~PATTERN
          (send
            (send nil? {:expect :allow}
              (const (const nil? :Gitlab) :Tracking)
            )
            ${:to :to_not :not_to}
            {
              (
                send nil? {:receive :have_received} (sym :event) ...
              )

              (send
                (send nil? {:receive :have_received} (sym :event)) ...
              )
            }
            ...
          )
        PATTERN

        def on_send(node)
          return unless expect_gitlab_tracking?(node)

          add_offense(node)
        end
      end
    end
  end
end
