# frozen_string_literal: true

module Gitlab
  module Config
    module Entry
      ##
      # Entry that represents a composable array definition
      #
      class ComposableArray < ::Gitlab::Config::Entry::Node
        include ::Gitlab::Config::Entry::Validatable
        include Gitlab::Utils::StrongMemoize

        # TODO: Refactor `Validatable` code so that validations can apply to a child class
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/263231
        validations do
          validates :config, type: Array
        end

        def compose!(deps = nil)
          super do
            @entries = Array(@entries)

            # TODO: Isolate handling for a hash via: `[@config].flatten` to the `Needs` entry
            # See: https://gitlab.com/gitlab-org/gitlab/-/issues/264376
            [@config].flatten.each_with_index do |value, index|
              raise ArgumentError, 'Missing Composable class' unless composable_class

              composable_class_name = composable_class.name.demodulize.underscore

              @entries << ::Gitlab::Config::Entry::Factory.new(composable_class)
                .value(value)
                .with(key: composable_class_name, parent: self, description: "#{composable_class_name} definition") # rubocop:disable CodeReuse/ActiveRecord
                .create!
            end

            @entries.each do |entry|
              entry.compose!(deps)
            end
          end
        end

        def value
          @entries.map(&:value)
        end

        def descendants
          @entries
        end

        def composable_class
          strong_memoize(:composable_class) do
            opt(:composable_class)
          end
        end
      end
    end
  end
end
