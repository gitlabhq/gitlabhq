# frozen_string_literal: true

module API
  module Entities
    class Appearance < Grape::Entity
      expose :title
      expose :description

      expose :logo do |appearance, options|
        appearance.logo.url
      end

      expose :header_logo do |appearance, options|
        appearance.header_logo.url
      end

      expose :favicon do |appearance, options|
        appearance.favicon.url
      end

      expose :new_project_guidelines
      expose :profile_image_guidelines
      expose :header_message
      expose :footer_message
      expose :message_background_color
      expose :message_font_color
      expose :email_header_and_footer_enabled
    end
  end
end
