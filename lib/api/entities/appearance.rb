# frozen_string_literal: true

module API
  module Entities
    class Appearance < Grape::Entity
      expose :title, documentation: { type: 'String', example: 'GitLab Community Edition' }
      expose :description, documentation: { type: 'String', example: 'Open source software to collaborate on code' }
      expose :pwa_name, documentation: { type: 'String', example: 'GitLab' }
      expose :pwa_short_name, documentation: { type: 'String', example: 'GitLab' }
      expose :pwa_description, documentation: { type: 'String', example: 'GitLab as PWA' }

      expose :logo,
        documentation: { type: 'String',
                         example: '/uploads/-/system/appearance/logo/1/logo.png' } do |appearance, options|
        appearance.logo.url
      end

      expose :pwa_icon,
        documentation: { type: 'String',
                         example: '/uploads/-/system/appearance/pwa_icon/1/icon.png' } do |appearance, options|
        appearance.pwa_icon.url
      end

      expose :header_logo,
        documentation: { type: 'String',
                         example: '/uploads/-/system/appearance/header_logo/1/header.png' } do |appearance, options|
        appearance.header_logo.url
      end

      expose :favicon,
        documentation: { type: 'String',
                         example: '/uploads/-/system/appearance/favicon/1/favicon.png' } do |appearance, options|
        appearance.favicon.url
      end

      expose :new_project_guidelines, documentation: { type: 'String', example: 'Please read the FAQs for help.' }
      expose :member_guidelines, documentation: { type: 'String', example: 'Please read the member guidelines.' }
      expose :profile_image_guidelines, documentation: { type: 'String', example: 'Custom profile image guidelines' }
      expose :header_message, documentation: { type: 'String', example: 'This is a header message' }
      expose :footer_message, documentation: { type: 'String', example: 'This is a footer message' }
      expose :message_background_color, documentation: { type: 'String', example: '#e75e40' }
      expose :message_font_color, documentation: { type: 'String', example: '#ffffff' }
      expose :email_header_and_footer_enabled, documentation: { type: 'Boolean', example: false }
      expose :site_name, documentation: { type: 'String', example: 'GitLab' }
    end
  end
end
