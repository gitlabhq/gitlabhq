# frozen_string_literal: true
module Pajamas
  class AvatarComponentPreview < ViewComponent::Preview
    # Avatar
    # ----
    # See its Pajamas design reference [here](https://design.gitlab.com/components/avatar).
    #
    # The avatar component takes a single `item` param and a couple of optional arguments:
    # - If the `item` is a plain `String`, this string will become the image `src`. In this case, also provide the
    #   `alt:` option, otherwise the resulting avatar image won't have an alt attribute.
    # - If the `item` is a `User` object, the avatar will have a round shape.
    # - For any other object (`Group`, `Project` etc) the shape will be rectangular with rounded corners.
    # @param src text
    # @param size select {{ Pajamas::AvatarComponent::SIZE_OPTIONS }}
    def default(src: ActionController::Base.helpers.image_path('logo.svg'), size: 64)
      render(Pajamas::AvatarComponent.new(src, size: size))
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
