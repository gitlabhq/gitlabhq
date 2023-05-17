# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents the path to be published with Pages.
        #
        class Publish < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, type: String
          end

          def self.default
            'public'
          end
        end
      end
    end
  end
end
