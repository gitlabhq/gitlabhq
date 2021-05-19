# frozen_string_literal: true

module QA
  module Page
    module Alert
      class FreeTrial < Chemlab::Page
        # TODO: Supplant with data-qa-selectors
        h4 :trial_activated_message, class: 'gl-banner-title'
      end
    end
  end
end
