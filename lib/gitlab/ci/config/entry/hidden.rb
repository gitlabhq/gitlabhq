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

          def relevant?
            false
          end
        end
      end
    end
  end
end
