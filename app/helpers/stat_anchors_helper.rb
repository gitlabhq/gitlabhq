# frozen_string_literal: true

module StatAnchorsHelper
  def stat_anchor_attrs(anchor)
    {}.tap do |attrs|
      attrs[:class] = %w[nav-link] << extra_classes(anchor)
      attrs[:itemprop] = anchor.itemprop if anchor.itemprop
      attrs[:data] = anchor.data if anchor.data
    end
  end

  private

  def button_attribute(anchor)
    anchor.class_modifier || 'btn-link gl-button !gl-text-link'
  end

  def extra_classes(anchor)
    if anchor.is_link
      'stat-link !gl-px-0 !gl-pb-2'
    else
      "stat-link !gl-px-0 !gl-pb-2 #{button_attribute(anchor)}"
    end
  end
end
