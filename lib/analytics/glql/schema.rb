# frozen_string_literal: true

require 'gitlab_query_language'

module Analytics
  module Glql
    # The GLQL schema document, as served by `GET /api/v4/glql/schema`.
    #
    # Everything but `display_types` comes from the gitlab_query_language gem.
    class Schema
      # `display:` is a frontend concern - the compiler never parses it, and
      # what renders depends on the presenters this version ships. Keeping the
      # list here means a new display type is one MR rather than a gem release.
      #
      # The frontend renders from its own DISPLAY_TYPES in
      # app/assets/javascripts/glql/constants.js; a spec asserts the two agree.
      # A type listed here but not there reaches users as an error in the block.
      DISPLAY_TYPES = [
        { 'name' => 'list', 'description' => 'A bulleted list of items.' },
        { 'name' => 'orderedList', 'description' => 'A numbered list of items.' },
        { 'name' => 'table', 'description' => 'One row per item, one column per display field.' },
        { 'name' => 'stat',
          'description' => 'A single aggregate value. Expects one metric and no dimensions.' },
        { 'name' => 'columnChart', 'description' => 'Vertical bars, one per dimension value.' },
        { 'name' => 'barChart', 'description' => 'Horizontal bars, one per dimension value.' },
        { 'name' => 'lineChart',
          'description' => 'A line over an ordered dimension, typically a date.' },
        { 'name' => 'areaChart',
          'description' => 'A filled line over an ordered dimension, typically a date.' }
      ].each(&:freeze).freeze

      class << self
        # Frozen because it is memoized and handed out by reference. The gem
        # freezes its half; `merge` returns a fresh hash and `DISPLAY_TYPES` is
        # already frozen.
        #
        # `::Glql` is the gem: a bare `Glql` here resolves to this module.
        def document
          @document ||= ::Glql.schema.merge('display_types' => DISPLAY_TYPES).freeze
        end
      end
    end
  end
end
