# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a hidden CI/CD key.
        #
        class Hidden < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, presence: true
          end

          def self.matching?(name, config)
            name.to_s.start_with?('.')
          end

          def self.visible?
            false
          end

          def relevant?
            false
          end
        end
      end
    end
  end
end
