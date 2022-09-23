# frozen_string_literal: true

module Pajamas
  class ProgressComponentPreview < ViewComponent::Preview
    # Progress
    # ---
    #
    # See its design reference [here](https://design.gitlab.com/components/progress-bar).
    #
    # @param value number
    # @param variant select [primary, success]
    def default(value: 50, variant: :primary)
      render Pajamas::ProgressComponent.new(value: value, variant: variant)
    end
  end
end
