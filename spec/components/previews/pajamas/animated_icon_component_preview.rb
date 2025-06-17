# frozen_string_literal: true

module Pajamas
  class AnimatedIconComponentPreview < ViewComponent::Preview
    # Render morphing example icon
    # @param variant select {{ Pajamas::AnimatedIconComponent::VARIANT_CLASSES.keys }}
    def morph(variant: :current, is_on: false)
      todo_component = Pajamas::AnimatedIconComponent.new(
        icon: :todo,
        variant: variant.to_sym,
        is_on: is_on
      )
      star_component = Pajamas::AnimatedIconComponent.new(
        icon: :star,
        variant: variant.to_sym,
        is_on: is_on
      )
      sort_component = Pajamas::AnimatedIconComponent.new(
        icon: :sort,
        variant: variant.to_sym,
        is_on: is_on
      )
      smile_component = Pajamas::AnimatedIconComponent.new(
        icon: :smile,
        variant: variant.to_sym,
        is_on: is_on
      )
      sidebar_component = Pajamas::AnimatedIconComponent.new(
        icon: :sidebar,
        variant: variant.to_sym,
        is_on: is_on
      )
      notification_component = Pajamas::AnimatedIconComponent.new(
        icon: :notifications,
        variant: variant.to_sym,
        is_on: is_on
      )
      chevron_right_down_component = Pajamas::AnimatedIconComponent.new(
        icon: :chevron_right_down,
        variant: variant.to_sym,
        is_on: is_on
      )
      chevron_lg_right_down_component = Pajamas::AnimatedIconComponent.new(
        icon: :chevron_lg_right_down,
        variant: variant.to_sym,
        is_on: is_on
      )
      chevron_down_up_component = Pajamas::AnimatedIconComponent.new(
        icon: :chevron_down_up,
        variant: variant.to_sym,
        is_on: is_on
      )
      chevron_lg_down_up_component = Pajamas::AnimatedIconComponent.new(
        icon: :chevron_lg_down_up,
        variant: variant.to_sym,
        is_on: is_on
      )

      render_with_template(template: 'animated_icon_component_preview/morph', locals: {
        todo_component: todo_component,
        star_component: star_component,
        sort_component: sort_component,
        smile_component: smile_component,
        sidebar_component: sidebar_component,
        notification_component: notification_component,
        chevron_right_down_component: chevron_right_down_component,
        chevron_lg_right_down_component: chevron_lg_right_down_component,
        chevron_down_up_component: chevron_down_up_component,
        chevron_lg_down_up_component: chevron_lg_down_up_component
      })
    end

    # Render infinite example icon
    # @param variant select {{ Pajamas::AnimatedIconComponent::VARIANT_CLASSES.keys }}
    def infinite(icon: :upload, variant: :current, is_on: true)
      upload_component = Pajamas::AnimatedIconComponent.new(
        icon: icon.to_sym,
        variant: variant.to_sym,
        is_on: is_on
      )
      duo_chat_component = Pajamas::AnimatedIconComponent.new(
        icon: :duo_chat,
        variant: variant.to_sym,
        is_on: is_on
      )
      loader_component = Pajamas::AnimatedIconComponent.new(
        icon: :loader,
        variant: variant.to_sym,
        is_on: is_on
      )

      render_with_template(template: 'animated_icon_component_preview/infinite', locals: {
        upload_component: upload_component,
        duo_chat_component: duo_chat_component,
        loader_component: loader_component
      })
    end
  end
end
