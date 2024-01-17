# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Instance
        class NonBlocking < All
          tags :"~reliable", :"~blocking", :"~smoke", *Specs::Runner::DEFAULT_SKIPPED_TAGS.map { |tag| :"~#{tag}" }
        end
      end
    end
  end
end
