# frozen_string_literal: true
module Pajamas
  class SpinnerComponentPreview < ViewComponent::Preview
    # Spinner
    # ----
    # See its design reference [here](https://design.gitlab.com/components/spinner).
    #
    # @param inline toggle
    # @param label text
    # @param size select {{ Pajamas::SpinnerComponent::SIZE_OPTIONS }}
    def default(inline: false, label: "Loading", size: :md)
      render Pajamas::SpinnerComponent.new(
        inline: inline,
        label: label,
        size: size
      )
    end

    # Use a light spinner on dark backgrounds.
    #
    # @display bg_dark true
    def light
      render(Pajamas::SpinnerComponent.new(color: :light))
    end

    # Any extra HTML attributes like `class`, `data` or `id` get automatically applied to the spinner container element.
    #
    def extra_attributes
      render Pajamas::SpinnerComponent.new(
        class: "js-do-something",
        data: { foo: "bar" },
        id: "my-special-spinner"
      )
    end
  end
end
