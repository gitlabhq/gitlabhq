# frozen_string_literal: true

module QA
  module Scenario
    class Template
      class << self
        def perform(*args)
          new.tap do |scenario|
            yield scenario if block_given?
            break scenario.perform(*args)
          end
        end

        def tags(*tags)
          @tags = tags
        end

        def focus
          @tags.to_a
        end
      end

      def perform(options, *args)
        define_gitlab_address(options, args)

        # Save the scenario class name
        Runtime::Scenario.define(:klass, self.class.name)

        # Set large setup attribute
        Runtime::Scenario.define(:large_setup?, args.include?('can_use_large_setup'))

        ##
        # Configure browser
        #
        Runtime::Browser.configure!

        ##
        # Perform before hooks, which are different for CE and EE
        #
        QA::Runtime::Release.perform_before_hooks unless QA::Runtime::Env.dry_run

        Runtime::Feature.enable(options[:enable_feature]) if options.key?(:enable_feature)

        if options.key?(:disable_feature) && (@feature_enabled = Runtime::Feature.enabled?(options[:disable_feature]))
          Runtime::Feature.disable(options[:disable_feature])
        end

        Runtime::Feature.set(options[:set_feature_flags]) if options.key?(:set_feature_flags)

        Specs::Runner.perform do |specs|
          specs.tty = true
          specs.tags = self.class.focus
          specs.options = args if args.any?
        end
      ensure
        Runtime::Feature.disable(options[:enable_feature]) if options.key?(:enable_feature)
        Runtime::Feature.enable(options[:disable_feature]) if options.key?(:disable_feature) && @feature_enabled
      end

      def extract_address(name, options)
        address = options[name]
        validate_address(name, address)

        Runtime::Scenario.define(name, address)
      end

      private

      delegate :define_gitlab_address_attribute!, to: 'QA::Support::GitlabAddress'

      # Define gitlab address attribute
      #
      # Use first argument if a valid address, else use named argument or default to environment variable
      #
      # @param [Hash] options
      # @param [Array] args
      # @return [void]
      def define_gitlab_address(options, args)
        address_from_opt = Runtime::Scenario.attributes[:gitlab_address]

        return define_gitlab_address_attribute!(args.shift) if args.first && Runtime::Address.valid?(args.first)
        return define_gitlab_address_attribute!(address_from_opt) if address_from_opt

        define_gitlab_address_attribute!
      end
    end
  end
end

QA::Scenario::Template.prepend_mod_with('Scenario::Template', namespace: QA)
