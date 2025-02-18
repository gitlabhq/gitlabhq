# frozen_string_literal: true

module QA
  module Scenario
    class Template
      class << self
        def perform(...)
          new.tap do |scenario|
            yield scenario if block_given?
            break scenario.perform(...)
          end
        end

        def tags(*tags)
          @tags = tags
        end

        def focus
          @tags.to_a
        end

        # Pipeline mapping for this scenario
        #
        # Defines pipeline mapping hash for this scenario
        # Mapping must use one of the pipeline types defined in QA::Ci::Tools::PipelineCreator::SUPPORTED_PIPELINES
        # and an array of jobs which must exist in that pipeline
        #
        # @example
        # pipeline_mappings test_on_cng: ['cng-instance'], test_on_gdk: ['gdk-instance']
        #
        # @return [Hash<String, Array<String>>]
        def pipeline_mappings(**kwargs)
          @pipeline_mapping = kwargs
        end

        # Glob pattern limiting which specs scenario can run
        #
        # @param pattern [String]
        # @return [String]
        def spec_glob_pattern(pattern)
          unless pattern.is_a?(String) && pattern.end_with?("_spec.rb")
            raise ArgumentError, "Scenario #{self.class.name} defines pattern that is not matching only spec files"
          end

          @spec_pattern = pattern
        end

        attr_reader :pipeline_mapping, :spec_pattern
      end

      def perform(options, *args)
        define_gitlab_address(args)

        # Store passed options globally
        Support::GlobalOptions.set(options)

        # Save the scenario class name
        Runtime::Scenario.define(:klass, self.class.name)

        # Set large setup attribute
        Runtime::Scenario.define(:large_setup?, args.include?('can_use_large_setup'))

        Specs::Runner.perform do |specs|
          specs.tty = true
          specs.tags = self.class.focus
          specs.spec_pattern = self.class.spec_pattern
          specs.options = args if args.any?
        end
      end

      private

      delegate :define_gitlab_address_attribute!, to: QA::Support::GitlabAddress

      # Define gitlab address attribute
      #
      # Use first argument if a valid address, else use named argument or default to environment variable
      #
      # @param [Array] args
      # @return [void]
      def define_gitlab_address(args)
        address_from_opt = Runtime::Scenario.attributes[:gitlab_address]

        return define_gitlab_address_attribute!(args.shift) if args.first && Runtime::Address.valid?(args.first)
        return define_gitlab_address_attribute!(address_from_opt) if address_from_opt

        define_gitlab_address_attribute!
      end
    end
  end
end

QA::Scenario::Template.prepend_mod_with('Scenario::Template', namespace: QA)
