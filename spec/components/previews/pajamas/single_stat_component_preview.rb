# frozen_string_literal: true

module Pajamas
  class SingleStatComponentPreview < ViewComponent::Preview
    # SingleStat
    # ---
    #
    # See its design reference [here](https://design.gitlab.com/data-visualization/single-stat).
    #
    # @param title text
    # @param stat_value text
    # @param unit text
    # @param title_icon text
    # @param meta_text text
    # @param meta_icon text
    # @param variant select {{ Pajamas::BadgeComponent::VARIANT_OPTIONS }}
    def default(
      title: 'Single stat',
      stat_value: '9,001',
      unit: '',
      title_icon: 'chart',
      meta_text: '',
      meta_icon: 'check-circle',
      variant: :default
    )
      render Pajamas::SingleStatComponent.new(
        title: title,
        stat_value: stat_value,
        unit: unit,
        title_icon: title_icon,
        meta_text: meta_text,
        meta_icon: meta_icon,
        variant: variant
      )
    end
  end
end
