# frozen_string_literal: true

module ReleasesHelper
  IMAGE_PATH = 'illustrations/releases.svg'
  DOCUMENTATION_PATH = 'user/project/releases/index'

  def illustration
    image_path(IMAGE_PATH)
  end

  def help_page
    help_page_path(DOCUMENTATION_PATH)
  end

  def data_for_releases_page
    {
      project_id: @project.id,
      illustration_path: illustration,
      documentation_path: help_page
    }
  end
end
