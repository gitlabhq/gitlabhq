# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Instance
        class ReviewBlocking < All
          tags :reliable,
               :sanity_feature_flags,
               :"~orchestrated",
               :"~skip_signup_disabled"
        end
      end
    end
  end
end
