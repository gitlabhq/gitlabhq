# frozen_string_literal: true

module Gitlab
  module Config
    module Entry
      ##
      # Entry that represents a composable hash definition
      # Where each hash key can be any value written by the user
      #
      class ComposableHash < ::Gitlab::Config::Entry::Node
        include ::Gitlab::Config::Entry::Validatable

        # TODO: Refactor `Validatable` code so that validations can apply to a child class
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/263231
        validations do
          validates :config, type: Hash
        end

        def compose!(deps = nil)
          super do
            @config.each do |name, config|
              entry_class = composable_class(name, config)
              raise ArgumentError, 'Missing Composable class' unless entry_class

              entry_class_name = entry_class.name.demodulize.underscore

              factory = ::Gitlab::Config::Entry::Factory.new(entry_class)
                .value(config.nil? ? {} : config)
                .with(key: name, parent: self, description: "#{name} #{entry_class_name} definition") # rubocop:disable CodeReuse/ActiveRecord
                .metadata(composable_metadata.merge(name: name))

              @entries[name] = factory.create!
            end

            @entries.each_value do |entry|
              entry.compose!(deps)
            end
          end
        end

        private

        def composable_class(name, config)
          opt(:composable_class)
        end

        def composable_metadata
          {}
        end
      end
    end
  end
end
