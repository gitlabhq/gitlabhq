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

            validate do
              next unless opt(:max_size)
              next unless config.is_a?(Array)

              if config.size > opt(:max_size)
                errors.add(:config, "is too long (maximum is #{opt(:max_size)})")
              end
            end
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
