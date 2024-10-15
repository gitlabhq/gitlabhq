# frozen_string_literal: true

module AppearancesHelper
  include MarkupHelper
  include Gitlab::Utils::StrongMemoize

  def appearance_pwa_icon_path_scaled(width)
    return unless Appearance::ALLOWED_PWA_ICON_SCALER_WIDTHS.include?(width)

    append_root_path((current_appearance&.pwa_icon_path_scaled(width) || "/-/pwa-icons/logo-#{width}.png"))
  end

  def appearance_maskable_logo
    append_root_path('/-/pwa-icons/maskable-logo.png')
  end

  def append_root_path(path)
    Gitlab::Utils.append_path(Gitlab.config.gitlab.relative_url_root, path)
  end

  def brand_title
    current_appearance&.title.presence || default_brand_title
  end

  def appearance_apple_touch_icon
    link_tags = favicon_link_tag('apple-touch-icon.png', rel: 'apple-touch-icon')

    return link_tags unless current_appearance&.pwa_icon.present?

    link_tags = favicon_link_tag(
      appearance_pwa_icon_path_scaled(Appearance::ALLOWED_PWA_ICON_SCALER_WIDTHS.first),
      rel: 'apple-touch-icon'
    )

    Appearance::ALLOWED_PWA_ICON_SCALER_WIDTHS.each do |width|
      link_tags += "\n"
      link_tags += favicon_link_tag(appearance_pwa_icon_path_scaled(width),
        sizes: "#{width}x#{width}", rel: 'apple-touch-icon')
    end

    link_tags
  end

  def appearance_pwa_name
    current_appearance&.pwa_name.presence || _('GitLab')
  end

  def appearance_pwa_short_name
    current_appearance&.pwa_short_name.presence || _('GitLab')
  end

  def appearance_pwa_description
    current_appearance&.pwa_description.presence ||
      _("The complete DevOps platform. " \
        "One application with endless possibilities. " \
        "Organizations rely on GitLab’s source code management, " \
        "CI/CD, security, and more to deliver software rapidly.")
  end

  def default_brand_title
    # This resides in a separate method so that EE can easily redefine it.
    _('GitLab Community Edition')
  end

  def brand_image
    image_tag(brand_image_path, alt: brand_title, class: 'gl-invisible gl-h-10 js-portrait-logo-detection')
  end

  def brand_image_path
    return current_appearance.logo_path if current_appearance&.logo?

    image_path('logo.svg')
  end

  def custom_sign_in_description
    markdown_field(current_appearance, :description)
  end

  def brand_member_guidelines
    markdown_field(current_appearance, :member_guidelines)
  end

  def brand_new_project_guidelines
    markdown_field(current_appearance, :new_project_guidelines)
  end

  def brand_profile_image_guidelines
    markdown_field(current_appearance, :profile_image_guidelines)
  end

  def current_appearance
    strong_memoize(:current_appearance) do
      Appearance.current
    end
  end

  def brand_header_logo(options = {})
    add_gitlab_logo_text = options[:add_gitlab_logo_text] || false

    if current_appearance&.header_logo?
      image_tag current_appearance.header_logo_path, class: 'brand-header-logo', alt: ''
    elsif add_gitlab_logo_text
      render partial: 'shared/logo_with_text', formats: :svg
    else
      render partial: 'shared/logo', formats: :svg
    end
  end

  def header_message
    return unless current_appearance&.show_header?

    class_names = []
    class_names << 'with-performance-bar' if performance_bar_enabled?

    render_message(:header_message, class_names: class_names)
  end

  def footer_message
    return unless current_appearance&.show_footer?

    render_message(:footer_message)
  end

  private

  def render_message(field_sym, class_names: [], style: message_style)
    class_names << field_sym.to_s.dasherize

    content_tag :div, class: class_names, style: style do
      markdown_field(current_appearance, field_sym)
    end
  end

  def message_style
    style = []
    style << "background-color: #{current_appearance.message_background_color};"
    style << "color: #{current_appearance.message_font_color}"
    style.join
  end
end

AppearancesHelper.prepend_mod
