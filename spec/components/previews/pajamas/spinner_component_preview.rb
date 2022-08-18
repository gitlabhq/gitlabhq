# frozen_string_literal: true
module Pajamas
  class SpinnerComponentPreview < ViewComponent::Preview
    # Spinner
    # ----
    # See its design reference [here](https://design.gitlab.com/components/spinner).
    #
    # @param inline toggle
    # @param label text
    # @param size select [[small, sm], [medium, md], [large, lg], [extra large, xl]]
    def default(inline: false, label: "Loading", size: :md)
      render(Pajamas::SpinnerComponent.new(inline: inline, label: label, size: size))
    end

    # Use a light spinner on dark backgrounds
    #
    # @display bg_color "#222"
    def light
      render(Pajamas::SpinnerComponent.new(color: :light))
    end
  end
end
