# frozen_string_literal: true

module Gitlab
  module StaticSiteEditor
    module Config
      class FileConfig
        module Entry
          ##
          # Entry that represents the path to which images will be uploaded
          #
          class ImageUploadPath < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable

            validations do
              validates :config, type: String
            end

            def self.default
              'source/images'
            end
          end
        end
      end
    end
  end
end
