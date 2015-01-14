module AppearancesHelper
  def brand_title
    if brand_item
      brand_item.title
    else
      'GitLab Enterprise Edition'
    end
  end

  def brand_image
    if brand_item.logo?
      image_tag brand_item.logo
    else
      nil
    end
  end

  def brand_header_logo
    if brand_item.header_logos?
      haml_tag(:style) do
        # Dark theme/light logo
        haml_concat ".dark_theme .app_logo a h1 {" \
                    "background: url('#{brand_item.light_logo}') " \
                    "no-repeat center center !important; }"
        # Light theme/dark logo
        haml_concat ".light_theme .app_logo a h1 {" \
                    "background: url('#{brand_item.dark_logo}') " \
                    "no-repeat center center !important; }"
      end
    end
  end

  def brand_text
    markdown(brand_item.description)
  end

  def brand_item
    @appearance ||= Appearance.first
  end
end
