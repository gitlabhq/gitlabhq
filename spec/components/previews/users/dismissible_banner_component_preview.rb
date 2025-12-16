# frozen_string_literal: true

module Users
  # @label User Dismissible Banner
  # @display wrapper false
  class DismissibleBannerComponentPreview < ViewComponent::Preview
    # @label Default User dismissal
    # @param button_text text
    # @param button_link text
    # @param content textarea
    # @param variant select {{ Pajamas::BannerComponent::VARIANT_OPTIONS }
    # @param feature_id select {{ Users::Callout.feature_names.keys }}
    def default(
      button_text: "Learn more",
      button_link: "https://about.gitlab.com/",
      content: "Add your message here.",
      variant: :promotion,
      feature_id: :suggest_pipeline
    )
      render(Users::DismissibleBannerComponent.new(
        button_text: button_text,
        button_link: button_link,
        svg_path: "illustrations/devops-sm.svg",
        variant: variant,
        dismiss_options: { feature_id: feature_id.to_sym, user: FactoryBot.build_stubbed(:user) }
      )) do
        content_tag :p, content
      end
    end

    # @label With Wrapper Options
    def with_wrapper
      render(Users::DismissibleBannerComponent.new(
        button_text: "Learn more",
        button_link: "https://about.gitlab.com/",
        svg_path: "illustrations/devops-sm.svg",
        variant: :promotion,
        dismiss_options: { feature_id: :web_ide_ci_environments_guidance, user: FactoryBot.build_stubbed(:user) },
        wrapper_options: { tag: :section, class: 'gl-p-5 gl-bg-gray-10', id: 'wrapped-banner' }
      )) do
        content_tag :p, 'This banner is wrapped in a custom container with additional styling and attributes.'
      end
    end
  end
end
