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
        extract_address(:gitlab_address, options, args)

        gitlab_address = URI(Runtime::Scenario.gitlab_address)

        # Define the "About" page as an `about` subdomain.
        # @example
        #   Given *gitlab_address* = 'https://gitlab.com/' #=> https://about.gitlab.com/
        #   Given *gitlab_address* = 'https://staging.gitlab.com/' #=> https://about.staging.gitlab.com/
        #   Given *gitlab_address* = 'http://gitlab-abc123.test/' #=> http://about.gitlab-abc123.test/
        Runtime::Scenario.define(:about_address, URI(-> { gitlab_address.host = "about.#{gitlab_address.host}"; gitlab_address }.call).to_s) # rubocop:disable Style/Semicolon

        ##
        # Perform before hooks, which are different for CE and EE
        #
        Runtime::Release.perform_before_hooks

        Runtime::Feature.enable(options[:enable_feature]) if options.key?(:enable_feature)

        Runtime::Feature.disable(options[:disable_feature]) if options.key?(:disable_feature) && (@feature_enabled = Runtime::Feature.enabled?(options[:disable_feature]))

        Specs::Runner.perform do |specs|
          specs.tty = true
          specs.tags = self.class.focus
          specs.options = args if args.any?
        end
      ensure
        Runtime::Feature.disable(options[:enable_feature]) if options.key?(:enable_feature)
        Runtime::Feature.enable(options[:disable_feature]) if options.key?(:disable_feature) && @feature_enabled
      end

      def extract_option(name, options, args)
        option = if options.key?(name)
                   options[name]
                 else
                   args.shift
                 end

        Runtime::Scenario.define(name, option)

        option
      end

      # For backwards-compatibility, if the gitlab instance address is not
      # specified as an option parsed by OptionParser, it can be specified as
      # the first argument
      def extract_address(name, options, args)
        address = extract_option(name, options, args)

        raise ::ArgumentError, "The address provided for `#{name}` is not valid: #{address}" unless Runtime::Address.valid?(address)
      end
    end
  end
end
