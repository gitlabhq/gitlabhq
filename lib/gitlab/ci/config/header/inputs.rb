# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Header
        class Inputs < ::Gitlab::Config::Entry::ComposableHash
          def compose!(deps = nil)
            super

            validate_rules! if @entries
          end

          private

          def composable_class(_name, _config)
            Header::Input
          end

          def validate_rules!
            Inputs::Validator.new(@entries).validate!
          end
        end
      end
    end
  end
end
