# frozen_string_literal: true

module Mcp
  module Tools
    module IconConfig
      GITLAB_ICON_PATH = 'gitlab_logo.png'

      def self.gitlab_icons
        icon_url = ActionController::Base.helpers.image_path(GITLAB_ICON_PATH, host: Gitlab.config.gitlab.url)
        [
          {
            mimeType: 'image/png',
            src: icon_url,
            theme: 'dark'
          },
          {
            mimeType: 'image/png',
            src: icon_url,
            theme: 'light'
          }
        ]
      end
    end
  end
end
