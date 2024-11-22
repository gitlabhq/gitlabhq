# frozen_string_literal: true
module Pajamas
  class BannerComponentPreview < ViewComponent::Preview
    # Banner
    # ----
    # See its design reference [here](https://design.gitlab.com/components/banner).
    #
    # @param button_text text
    # @param button_link text
    # @param content textarea
    # @param variant select {{ Pajamas::BannerComponent::VARIANT_OPTIONS }}
    def default(
      button_text: "Learn more",
      button_link: "https://about.gitlab.com/",
      content: "Add your message here.",
      variant: :promotion
    )
      render(Pajamas::BannerComponent.new(
        button_text: button_text,
        button_link: button_link,
        svg_path: "illustrations/devops-sm.svg",
        variant: variant
      )) do |c|
        content_tag :p, content
      end
    end

    # Use the `primary_action` slot instead of `button_text` and `button_link` if you need something more special,
    # like rendering a partial that holds your button.
    def with_primary_action_slot
      render(Pajamas::BannerComponent.new) do |c|
        c.with_primary_action do
          # You could also `render` another partial here.
          tag.button "I'm special", class: "btn btn-md btn-confirm gl-button"
        end
        content_tag :p, "This banner uses the primary_action slot."
      end
    end

    # Use the `illustration` slot instead of `svg_path` if your illustration is not part or the asset pipeline,
    # but for example, an inline SVG via `custom_icon`.
    def with_illustration_slot
      render(Pajamas::BannerComponent.new) do |c|
        c.with_illustration do
          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="white" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-thumbs-up"><path d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3zM7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3"></path></svg>'.html_safe # rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
        end
        content_tag :p, "This banner uses the illustration slot."
      end
    end
  end
end
