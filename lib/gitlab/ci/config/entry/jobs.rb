# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a set of jobs.
        #
        class Jobs < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, type: Hash

            validate do
              unless has_valid_jobs?
                errors.add(:config, 'should contain valid jobs')
              end

              unless has_visible_job?
                errors.add(:config, 'should contain at least one visible job')
              end
            end

            def has_valid_jobs?
              config.all? do |name, value|
                Jobs.find_type(name, value)
              end
            end

            def has_visible_job?
              config.any? do |name, value|
                Jobs.find_type(name, value)&.visible?
              end
            end
          end

          TYPES = [Entry::Hidden, Entry::Job].freeze

          private_constant :TYPES

          def self.all_types
            TYPES
          end

          def self.find_type(name, config)
            self.all_types.find do |type|
              type.matching?(name, config)
            end
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def compose!(deps = nil)
            super do
              @config.each do |name, config|
                node = self.class.find_type(name, config)
                next unless node

                factory = ::Gitlab::Config::Entry::Factory.new(node)
                  .value(config || {})
                  .metadata(name: name)
                  .with(key: name, parent: self,
                        description: "#{name} job definition.")

                @entries[name] = factory.create!
              end

              @entries.each_value do |entry|
                entry.compose!(deps)
              end
            end
          end
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
