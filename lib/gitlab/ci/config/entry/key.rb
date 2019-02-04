# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a key.
        #
        class Key < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, key: true
          end

          def self.default
            'default'
          end
        end
      end
    end
  end
end
