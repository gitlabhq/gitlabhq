# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a list of include.
        #
        class Includes < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, array_or_string: true
          end

          def self.aspects
            super.append -> do
              @config = Array.wrap(@config)

              @config.each_with_index do |config, i|
                @entries[i] = ::Gitlab::Config::Entry::Factory.new(Entry::Include)
                                .value(config || {})
                                .create!
              end
            end
          end
        end
      end
    end
  end
end
