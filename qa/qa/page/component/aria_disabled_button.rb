# frozen_string_literal: true

module QA
  module Page
    module Component
      # Helpers for checking whether a button-like element is disabled in a way
      # that is aware of both the native HTML `disabled` attribute and the ARIA
      # `aria-disabled="true"` attribute.
      #
      # GlButton renders `aria-disabled="true"` (instead of the native `disabled`
      # attribute) when the `accessible_disabled_button` feature flag is enabled
      # (see https://gitlab.com/gitlab-org/gitlab/-/issues/600158).
      # Capybara's built-in `Element#disabled?` only checks the native attribute,
      # so it returns `false` for aria-disabled buttons.  Use `element_disabled?`
      # wherever a GlButton's disabled state needs to be tested.
      module AriaDisabledButton
        # Returns true when the named element is disabled via either the
        # native `disabled` attribute or `aria-disabled="true"`.
        #
        # @param name [String] the data-testid of the element to check
        # @return [Boolean]
        def element_disabled?(name, **kwargs)
          element = find_element(name, **kwargs)
          element.disabled? || element['aria-disabled'] == 'true'
        end
      end
    end
  end
end
