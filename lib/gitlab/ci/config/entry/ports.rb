# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of the ports of a Docker service.
        #
        class Ports < ::Gitlab::Config::Entry::ComposableArray
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, type: Array
            validates :config, port_name_present_and_unique: true
            validates :config, port_unique: true
          end

          def composable_class
            Entry::Port
          end
        end
      end
    end
  end
end
