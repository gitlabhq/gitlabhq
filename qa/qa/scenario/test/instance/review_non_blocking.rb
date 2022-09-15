# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Instance
        class ReviewNonBlocking < All
          tags :"~reliable",
               :"~smoke",
               :"~skip_signup_disabled",
               *Specs::Runner::DEFAULT_SKIPPED_TAGS.map { |tag| :"~#{tag}" }
        end
      end
    end
  end
end
