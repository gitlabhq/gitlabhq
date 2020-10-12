# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of Docker services.
        #
        class Services < ::Gitlab::Config::Entry::ComposableArray
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, type: Array
            validates :config, services_with_ports_alias_unique: true, if: ->(record) { record.opt(:with_image_ports) }
          end

          def composable_class
            Entry::Service
          end
        end
      end
    end
  end
end
