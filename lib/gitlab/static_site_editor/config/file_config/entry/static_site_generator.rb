# frozen_string_literal: true

module Gitlab
  module StaticSiteEditor
    module Config
      class FileConfig
        module Entry
          ##
          # Entry that represents the static site generator tool/framework.
          #
          class StaticSiteGenerator < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable

            validations do
              validates :config, type: String, inclusion: { in: %w[middleman], message: "should be 'middleman'" }
            end

            def self.default
              'middleman'
            end
          end
        end
      end
    end
  end
end
