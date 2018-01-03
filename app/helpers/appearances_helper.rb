module AppearancesHelper
  def brand_title
    brand_item&.title.presence || 'GitLab Community Edition'
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
