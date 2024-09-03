# frozen_string_literal: true

module Onboarding
  class ActionCardComponentPreview < ViewComponent::Preview
    # Action card
    # ---
    #
    # @param icon select [~, star-o, issue-closed, group]
    # @param href url
    # @param description text
    # @param title text
    # @param variant select {{ Onboarding::ActionCardComponent::VARIANT_OPTIONS }}
    def default(
      icon: :group,
      variant: :default,
      href: "gitlab.com",
      description: "Groups are the best way to manage projects and members",
      title: "Create a group")
      render Onboarding::ActionCardComponent.new(
        title: title,
        description: description,
        icon: icon,
        href: href,
        variant: variant
      )
    end
  end
end
