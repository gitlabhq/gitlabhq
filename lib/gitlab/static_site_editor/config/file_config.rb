# frozen_string_literal: true

module Gitlab
  module StaticSiteEditor
    module Config
      class FileConfig
        def data
          {
            static_site_generator: 'middleman'
          }
        end
      end
    end
  end
end
