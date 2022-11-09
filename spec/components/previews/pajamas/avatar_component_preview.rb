# frozen_string_literal: true
module Pajamas
  class AvatarComponentPreview < ViewComponent::Preview
    # Avatar
    # ----
    # See its design reference [here](https://design.gitlab.com/components/avatar).
    def default
      user
    end

    # We show user avatars in a circle.
    # @param size select {{ Pajamas::AvatarComponent::SIZE_OPTIONS }}
    def user(size: 64)
      render(Pajamas::AvatarComponent.new(User.first, size: size))
    end

    # @param size select {{ Pajamas::AvatarComponent::SIZE_OPTIONS }}
    def project(size: 64)
      render(Pajamas::AvatarComponent.new(Project.first, size: size))
    end

    # @param size select {{ Pajamas::AvatarComponent::SIZE_OPTIONS }}
    def group(size: 64)
      render(Pajamas::AvatarComponent.new(Group.first, size: size))
    end
  end
end
