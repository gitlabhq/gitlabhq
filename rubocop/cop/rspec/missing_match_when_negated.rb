# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module RSpec
      # Detects custom RSpec matchers whose `match` block queries the DOM via
      # Capybara without defining `match_when_negated`.
      #
      # Capybara's positive query methods (`has_selector?`, `have_selector`,
      # `find_by_testid`, etc.) wait up to `default_max_wait_time` for the
      # element to appear. When a custom matcher uses these in `match` and the
      # matcher is used as `not_to`, RSpec falls back to negating `match`,
      # which still waits the full timeout when the element is absent. The
      # assertion is correct but slow.
      #
      # Define `match_when_negated` using Capybara's negative-waiting
      # counterparts (`has_no_selector?`, `assert_no_selector`, etc.) so the
      # negated path returns as soon as the element is confirmed absent.
      #
      # @example
      #
      #   # bad
      #   RSpec::Matchers.define :have_testid do |testid|
      #     match do |actual|
      #       actual.has_selector?("[data-testid='#{testid}']")
      #     end
      #   end
      #
      #   # good
      #   RSpec::Matchers.define :have_testid do |testid|
      #     match do |actual|
      #       actual.has_selector?("[data-testid='#{testid}']")
      #     end
      #
      #     match_when_negated do |actual|
      #       actual.has_no_selector?("[data-testid='#{testid}']")
      #     end
      #   end
      class MissingMatchWhenNegated < RuboCop::Cop::Base
        MSG = 'Custom matcher uses Capybara DOM queries in `match` but does ' \
          'not define `match_when_negated`. `not_to` against this matcher ' \
          'falls back to negating `match` and waits the full Capybara ' \
          'timeout. Define `match_when_negated` using the negative-waiting ' \
          'counterpart (e.g., `has_no_selector?`).'

        # Capybara positive query methods that wait for the element to appear.
        # Calling these inside `match` makes `not_to` slow when no
        # `match_when_negated` block is defined.
        CAPYBARA_QUERY_METHODS = %i[
          has_selector? has_css? has_xpath?
          has_text? has_content?
          has_link? has_button? has_field?
          has_select? has_checked_field? has_unchecked_field?
          has_table? has_title? has_current_path?
          have_selector have_css have_xpath
          have_text have_content
          have_link have_button have_field
          have_select have_checked_field have_unchecked_field
          have_table have_title have_current_path
        ].to_set.freeze

        # GitLab `data-testid` helpers that wrap Capybara query methods with
        # identical wait-for-presence semantics.
        GITLAB_DOM_HELPERS = %i[
          find_by_testid has_testid?
        ].to_set.freeze

        DOM_QUERY_METHODS = (CAPYBARA_QUERY_METHODS | GITLAB_DOM_HELPERS).freeze

        BLOCK_TYPES = %i[block numblock].freeze

        # @!method matcher_define_block?(node)
        def_node_matcher :matcher_define_block?, <<~PATTERN
          ({block numblock}
            (send (const (const {nil? cbase} :RSpec) :Matchers) :define _)
            _ _)
        PATTERN

        # @!method match_block?(node)
        def_node_matcher :match_block?, <<~PATTERN
          ({block numblock} (send nil? :match) _ _)
        PATTERN

        # @!method match_when_negated_block?(node)
        def_node_matcher :match_when_negated_block?, <<~PATTERN
          ({block numblock} (send nil? :match_when_negated) _ _)
        PATTERN

        def on_block(node)
          return unless matcher_define_block?(node)

          match_block = find_match_block(node)
          return unless match_block
          return unless contains_dom_query?(match_block)
          return if match_when_negated?(node)

          add_offense(match_block.send_node)
        end
        alias_method :on_numblock, :on_block

        private

        def find_match_block(define_node)
          each_child_block(define_node).find { |child| match_block?(child) }
        end

        def match_when_negated?(define_node)
          each_child_block(define_node).any? { |child| match_when_negated_block?(child) }
        end

        def each_child_block(define_node)
          body = define_node.body
          return [].each unless body

          children = body.begin_type? ? body.children : [body]
          children.select { |c| BLOCK_TYPES.include?(c.type) }.each
        end

        def contains_dom_query?(match_block)
          match_block.each_descendant(:send).any? do |send_node|
            DOM_QUERY_METHODS.include?(send_node.method_name)
          end
        end
      end
    end
  end
end
