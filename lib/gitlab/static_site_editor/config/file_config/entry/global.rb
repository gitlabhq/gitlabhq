# frozen_string_literal: true

module Gitlab
  module StaticSiteEditor
    module Config
      class FileConfig
        module Entry
          ##
          # This class represents a global entry - root Entry for entire
          # GitLab StaticSiteEditor Configuration file.
          #
          class Global < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Configurable
            include ::Gitlab::Config::Entry::Attributable

            ALLOWED_KEYS = %i[
              image_upload_path
              mounts
              static_site_generator
            ].freeze

            attributes ALLOWED_KEYS

            validations do
              validates :config, allowed_keys: ALLOWED_KEYS
            end

            entry :image_upload_path, Entry::ImageUploadPath,
                  description: 'Configuration of the Static Site Editor image upload path.'
            entry :mounts, Entry::Mounts,
                  description: 'Configuration of the Static Site Editor mounts.'
            entry :static_site_generator, Entry::StaticSiteGenerator,
                  description: 'Configuration of the Static Site Editor static site generator.'
          end
        end
      end
    end
  end
end
