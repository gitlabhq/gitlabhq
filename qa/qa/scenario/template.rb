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
        gitlab_address = extract_gitlab_address(options, args)

        # Define the "About" page as an `about` subdomain.
        # @example
        #   Given *gitlab_address* = 'https://gitlab.com/' #=> https://about.gitlab.com/
        #   Given *gitlab_address* = 'https://staging.gitlab.com/' #=> https://about.staging.gitlab.com/
        #   Given *gitlab_address* = 'http://gitlab-abc123.test/' #=> http://about.gitlab-abc123.test/
        Runtime::Scenario.define(:about_address, gitlab_address.tap { |add| add.host = "about.#{add.host}" }.to_s)

        # Save the scenario class name
        Runtime::Scenario.define(:klass, self.class.name)

        ##
        # Setup knapsack and download latest report
        #
        Tools::KnapsackReport.configure! if Runtime::Env.knapsack?

        ##
        # Perform before hooks, which are different for CE and EE
        #
        Runtime::Release.perform_before_hooks unless Runtime::Env.dry_run

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

      # For backwards-compatibility, if the gitlab instance address is not
      # specified as an option parsed by OptionParser, it can be specified as
      # the first argument
      def extract_gitlab_address(options, args)
        opt_name = :gitlab_address
        address_from_opt = Runtime::Scenario.attributes[opt_name]
        # return gitlab address if it was set via named option already
        return validate_address(opt_name, address_from_opt) && URI(address_from_opt) if address_from_opt

        address = if args.first.nil? || File.exist?(args.first)
                    # if first arg is a valid path and not address, it's a spec file, default to environment variable
                    Runtime::Env.gitlab_url
                  else
                    args.shift
                  end

        validate_address(opt_name, address)
        Runtime::Scenario.define(opt_name, address)

        URI(address)
      end

      def validate_address(name, address)
        Runtime::Address.valid?(address) || raise(
          ::ArgumentError, "Configured address parameter '#{name}' is not a valid url: #{address}"
        )
      end
    end
  end
end
