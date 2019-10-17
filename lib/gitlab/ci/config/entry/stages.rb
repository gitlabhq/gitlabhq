# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration for pipeline stages.
        #
        class Stages < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, array_of_strings: true
          end

          def self.default
            Config::EdgeStagesInjector.wrap_stages %w[build test deploy]
          end
        end
      end
    end
  end
end
