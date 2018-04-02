module AppearancesHelper
  prepend EE::AppearancesHelper

  def brand_title
<<<<<<< HEAD
    current_appearance&.title.presence || 'GitLab Enterprise Edition'
=======
    current_appearance&.title.presence || 'GitLab Community Edition'
>>>>>>> upstream/master
  end

  def brand_image
    image_tag(current_appearance.logo) if current_appearance&.logo?
  end

  def brand_text
    markdown_field(current_appearance, :description)
  end

  def brand_new_project_guidelines
    markdown_field(current_appearance, :new_project_guidelines)
  end

  def current_appearance
    @appearance ||= Appearance.current
  end

  def brand_header_logo
    if current_appearance&.header_logo?
      image_tag current_appearance.header_logo
    else
      render 'shared/logo.svg'
    end
  end

  # Skip the 'GitLab' type logo when custom brand logo is set
  def brand_header_logo_type
    unless current_appearance&.header_logo?
      render 'shared/logo_type.svg'
    end
  end
end
