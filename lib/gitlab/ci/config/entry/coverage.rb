# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents Coverage settings.
        #
        class Coverage < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, regexp: true
          end

          def value
            @config[1...-1]
          end
        end
      end
    end
  end
end
