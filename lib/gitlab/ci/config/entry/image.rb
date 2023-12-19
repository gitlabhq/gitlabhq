# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a Docker image.
        #
        class Image < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Ci::Config::Entry::Imageable

          validations do
            validates :config, allowed_keys: IMAGEABLE_ALLOWED_KEYS
          end
        end
      end
    end
  end
end
