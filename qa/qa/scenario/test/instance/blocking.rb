# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Instance
        class Blocking < All
          tags :reliable, :blocking, *Specs::Runner::DEFAULT_SKIPPED_TAGS.map { |tag| :"~#{tag}" }
        end
      end
    end
  end
end
