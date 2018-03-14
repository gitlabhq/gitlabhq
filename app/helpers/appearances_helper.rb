module AppearancesHelper
  def header_message(appearance)
    return unless appearance.header_message.present?

    appearance_message(appearance, :header_message)
  end

  def footer_message(appearance)
    return unless appearance.footer_message.present?

    appearance_message(appearance, :footer_message)
  end

  def appearance_message(appearance, field_sym)
    class_names = [field_sym.to_s.dasherize]
    class_names << 'with-performance-bar' if performance_bar_enabled?

    content_tag :div, class: class_names, style: message_style(appearance) do
      icon('bullhorn') << ' ' << render_message(appearance, field_sym)
    end
  end

  def message_style(appearance)
    style = ''

    if appearance.background_color.present?
      style << "background-color: #{appearance.background_color}"
      style << '; ' if appearance.font_color.present?
    end

    if appearance.font_color.present?
      style << "color: #{appearance.font_color}"
    end

    style
  end

  def render_message(appearance, field)
    Banzai.render_field(appearance, field).html_safe
  end

  def brand_title
    brand_item&.title.presence || 'GitLab Enterprise Edition'
  end

  def brand_image
    image_tag(brand_item.logo) if brand_item&.logo?
  end

  def brand_text
    markdown_field(brand_item, :description)
  end

  def brand_new_project_guidelines
    markdown_field(brand_item, :new_project_guidelines)
  end

  def brand_item
    @appearance ||= Appearance.current
  end

  def brand_header_logo
    if brand_item&.header_logo?
      image_tag brand_item.header_logo
    else
      render 'shared/logo.svg'
    end
  end

  # Skip the 'GitLab' type logo when custom brand logo is set
  def brand_header_logo_type
    unless brand_item&.header_logo?
      render 'shared/logo_type.svg'
    end
  end
end
