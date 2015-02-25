module AppearancesHelper
  def brand_item
    nil
  end

  def brand_title
    'GitLab Community Edition'
  end

  def brand_image
    nil
  end

  def brand_text
    nil
  end

  def brand_header_logo
    if theme_type == 'light_theme'
      image_tag 'logo-black.png'
    else
      image_tag 'logo-white.png'
    end
  end
end
