# frozen_string_literal: true

module Pajamas
  class SelectComponentPreview < ViewComponent::Preview
    # Select
    # ---
    #
    # See its design reference [here](https://design.gitlab.com/components/select).
    #
    # @param width select {{ Pajamas::SelectComponent::WIDTH_OPTIONS }}
    def default(width: :md)
      render Pajamas::SelectComponent.new(
        name: :role,
        choices: [['Guest', 10], ['Reporter', 20], ['Developer', 30], ['Maintainer', 40]],
        selected: 20,
        width: width
      )
    end

    # Full width
    # ---
    #
    # Omit the `width` to let the select fill its container.
    def full_width
      render Pajamas::SelectComponent.new(
        name: :role,
        choices: [['Guest', 10], ['Reporter', 20], ['Developer', 30], ['Maintainer', 40]],
        selected: 20
      )
    end
  end
end
