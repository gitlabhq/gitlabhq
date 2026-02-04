# frozen_string_literal: true

module Users
  # @label Group Dismissible Banner
  # @display wrapper false
  class GroupDismissibleBannerComponentPreview < ViewComponent::Preview
    # @label Default Group dismissal
    # @param button_text text
    # @param button_link text
    # @param content textarea
    # @param variant select {{ Pajamas::BannerComponent::VARIANT_OPTIONS }
    # @param feature_id select {{ Users::GroupCallout.feature_names.keys }}
    def default(
      button_text: "Learn more",
      button_link: "https://about.gitlab.com/",
      content: "Add your message here.",
      variant: :promotion,
      feature_id: :preview_user_over_limit_free_plan_alert
    )
      render(Users::GroupDismissibleBannerComponent.new(
        button_text: button_text,
        button_link: button_link,
        svg_path: "illustrations/devops-sm.svg",
        variant: variant,
        dismiss_options: {
          feature_id: feature_id.to_sym, group: FactoryBot.build_stubbed(:group), user: FactoryBot.build_stubbed(:user)
        }
      )) do
        content_tag :p, content
      end
    end

    # @label With Wrapper Options
    def with_wrapper
      render(Users::GroupDismissibleBannerComponent.new(
        button_text: "Learn more",
        button_link: "https://about.gitlab.com/",
        svg_path: "illustrations/devops-sm.svg",
        variant: :promotion,
        dismiss_options: {
          feature_id: :preview_user_over_limit_free_plan_alert,
          group: FactoryBot.build_stubbed(:group),
          user: FactoryBot.build_stubbed(:user)
        },
        wrapper_options: { tag: :section, class: 'gl-p-5 gl-bg-gray-10', id: 'wrapped-banner' }
      )) do
        content_tag :p, 'This banner is wrapped in a custom container with additional styling and attributes.'
      end
    end
  end
end
