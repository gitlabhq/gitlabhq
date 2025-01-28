# frozen_string_literal: true
module Pajamas
  class ButtonComponentPreview < ViewComponent::Preview
    # Button
    # ----
    # See its design reference [here](https://design.gitlab.com/components/button).
    #
    # @param category select {{ Pajamas::ButtonComponent::CATEGORY_OPTIONS }}
    # @param variant select {{ Pajamas::ButtonComponent::VARIANT_OPTIONS }}
    # @param size select {{ Pajamas::ButtonComponent::SIZE_OPTIONS }}
    # @param type select {{ Pajamas::ButtonComponent::TYPE_OPTIONS }}
    # @param disabled toggle
    # @param loading toggle
    # @param block toggle
    # @param label toggle
    # @param selected toggle
    # @param icon select [~, star-o, issue-closed, tanuki]
    # @param text text
    def default( # rubocop:disable Metrics/ParameterLists
      category: :primary,
      variant: :default,
      size: :medium,
      type: :button,
      disabled: false,
      loading: false,
      block: false,
      label: false,
      selected: false,
      icon: nil,
      text: "Edit"
    )
      render(Pajamas::ButtonComponent.new(
        category: category,
        variant: variant,
        size: size,
        type: type,
        disabled: disabled,
        loading: loading,
        block: block,
        label: label,
        selected: selected,
        icon: icon
      )) do
        text.presence
      end
    end

    # The component can also be used to create links that look and feel like buttons.
    # Just provide a `href` and optionally a `target` to create an `<a>` tag.
    # For links with target="_blank", the component automatically adds rel="noopener noreferrer".
    #
    # @param target select {{ Pajamas::ButtonComponent::TARGET_OPTIONS }}
    def link(target: nil)
      render(Pajamas::ButtonComponent.new(
        href: "https://gitlab.com",
        target: target
      )) do
        "This is a link"
      end
    end
  end
end
