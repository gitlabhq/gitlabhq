# frozen_string_literal: true

module Gitlab
  module Changelog
    module Template
      # Context is used to provide a binding/context to ERB templates used for
      # rendering changelogs.
      #
      # This class extends BasicObject so that we only expose the bare minimum
      # needed to render the ERB template.
      class Context < BasicObject
        MAX_NESTED_LOOPS = 4

        def initialize(variables)
          @variables = variables
          @loop_nesting = 0
        end

        def get_binding
          ::Kernel.binding
        end

        def each(value, &block)
          max = MAX_NESTED_LOOPS

          if @loop_nesting == max
            ::Kernel.raise(
              ::Template::TemplateError.new("You can only nest up to #{max} loops")
            )
          end

          @loop_nesting += 1
          result = value.each(&block) if value.respond_to?(:each)
          @loop_nesting -= 1

          result
        end

        # rubocop: disable Style/TrivialAccessors
        def variables
          @variables
        end
        # rubocop: enable Style/TrivialAccessors

        def read(source, *steps)
          current = source

          steps.each do |step|
            case current
            when ::Hash
              current = current[step]
            when ::Array
              return '' unless step.is_a?(::Integer)

              current = current[step]
            else
              break
            end
          end

          current
        end

        def truthy?(value)
          value.respond_to?(:any?) ? value.any? : !!value
        end
      end
    end
  end
end
