# frozen_string_literal: true

require 'capybara/dsl'
require 'active_support/core_ext/array/extract_options'

module QA
  module Resource
    class Base
      include ApiFabricator
      extend Capybara::DSL

      using Rainbow

      NoValueError = Class.new(RuntimeError)

      attr_reader :retrieved_from_cache

      class << self
        # Initialize new instance of class without fabrication
        #
        # @yieldparam [self] instance of page object
        # @return [self]
        def init(&prepare_block)
          new.tap(&prepare_block)
        end

        # All instances of the Resource
        #
        # @return [Array<QA::Resource>]
        def all(api_client = nil, **kwargs)
          instance(api_client).all(**kwargs)
        end

        # TODO: remove, this method is redundant because normal fabricate! performs exactly the same check
        def fabricate_via_api_unless_fips!
          if Runtime::Env.personal_access_tokens_disabled?
            fabricate!
          else
            fabricate_via_api!
          end
        end

        def fabricate!(*args, &prepare_block)
          # TODO: move this check in to `api_support?` method to disable api support if tokens are disabled
          if Runtime::Env.personal_access_tokens_disabled?
            fabricate_via_browser_ui!(*args, &prepare_block)
          else
            fabricate_via_api!(*args, &prepare_block)
          end
        rescue NotImplementedError
          fabricate_via_browser_ui!(*args, &prepare_block)
        end

        def fabricate_via_browser_ui!(*args, &prepare_block)
          options = args.extract_options!
          resource = options.fetch(:resource) { new }
          parents = options.fetch(:parents) { [] }

          do_fabricate!(resource: resource, prepare_block: prepare_block) do
            log_and_record_fabrication(:browser_ui, resource, parents, args) { resource.fabricate!(*args) }

            current_url
          end
        end

        def fabricate_via_api!(*args, &prepare_block)
          options = args.extract_options!
          resource = options.fetch(:resource) { new }
          parents = options.fetch(:parents) { [] }

          raise NotImplementedError unless resource.api_support?

          do_fabricate!(resource: resource, prepare_block: prepare_block) do
            log_and_record_fabrication(:api, resource, parents, args) { resource.fabricate_via_api! }
          end
        end

        def remove_via_api!(*args, &prepare_block)
          options = args.extract_options!
          resource = options.fetch(:resource) { new }
          parents = options.fetch(:parents) { [] }

          do_fabricate!(resource: resource, prepare_block: prepare_block) do
            log_and_record_fabrication(:api, resource, parents, args) { resource.remove_via_api! }
          end
        end

        private

        # Override api client definition to use admin api client
        #
        # @return [void]
        def uses_admin_api_client
          define_method(:api_client) do
            @api_client ||= Runtime::User::Store.admin_api_client
          end
          private :api_client
        end

        def instance(api_client)
          init { |resource| resource.api_client = api_client || QA::Runtime::API::Client.as_admin }
        end

        def do_fabricate!(resource:, prepare_block:)
          prepare_block.call(resource) if prepare_block

          resource_web_url = yield
          resource.web_url = resource_web_url

          resource
        end

        def log_and_record_fabrication(fabrication_method, resource, parents, _args)
          start = Time.now

          Support::FabricationTracker.start_fabrication
          result = yield.tap do
            fabrication_time = Time.now - start

            Support::FabricationTracker.save_fabrication(:"#{fabrication_method}_fabrication", fabrication_time)

            unless resource.retrieved_from_cache || Runtime::Env.personal_access_tokens_disabled?
              Tools::TestResourceDataProcessor.collect(
                resource: resource,
                info: resource.identifier,
                fabrication_method: fabrication_method,
                fabrication_time: fabrication_time
              )
            end

            Runtime::Logger.info do
              msg = ["==#{'=' * parents.size}>"]
              msg << "#{fabrication_type(resource, fabrication_method)} a #{Rainbow(name).black.bg(:white)}"
              msg << resource.identifier
              msg << "as a dependency of #{parents.last}" if parents.any?
              msg << "via #{resource.retrieved_from_cache ? 'cache' : fabrication_method}"
              msg << "in #{fabrication_time.round(2)} seconds"

              msg.compact.join(' ')
            end
          end

          Support::FabricationTracker.finish_fabrication

          result
        end

        # Fetch type of fabrication, either resource was built or fetched
        #
        # @param [Resource] resource
        # @param [Symbol] method
        # @return [String]
        def fabrication_type(resource, method)
          return "Built" if method == :browser_ui || [:post, :put].include?(resource.api_fabrication_http_method)
          return "Retrieved" if resource.api_fabrication_http_method == :get || resource.retrieved_from_cache

          Runtime::Logger.warn("Resource fabrication http method has not been set properly, assuming :get value!")
          "Built"
        end

        # Define custom attribute
        #
        # @param [Symbol] name
        # @return [void]
        def attribute(name, &block)
          (@attribute_names ||= []).push(name) # save added attributes

          attr_writer(name)

          define_method(name) do
            return instance_variable_get(:"@#{name}") if instance_variable_defined?(:"@#{name}")

            instance_variable_set(:"@#{name}", attribute_value(name, block))
          end
        end

        # Define multiple custom attributes
        #
        # @param [Array] names
        # @return [void]
        def attributes(*names)
          names.each { |name| attribute(name) }
        end
      end

      # To be overridden by Resource classes to return a list of all instances of the resource
      #
      # @params [Hash] kwargs arguments to be used to query the API to search for resources with a specific criteria
      # @return [Array]
      def all(**kwargs)
        raise NotImplementedError
      end

      # Override api reload! and update custom attributes from api_resource
      #
      api_reload = instance_method(:reload!)
      define_method(:reload!) do
        api_reload.bind_call(self)
        return self unless api_resource

        all_attributes.each do |attribute_name|
          if api_resource.key?(attribute_name)
            instance_variable_set(:"@#{attribute_name}", api_resource[attribute_name])
          end
        end

        self
      end

      attribute :web_url

      def fabricate!(*_args)
        raise NotImplementedError
      end

      def visit!(skip_finished_loading_check: false, skip_resp_code_check: false)
        Runtime::Logger.info("Visiting #{Rainbow(self.class.name).black.bg(:white)} at #{web_url}")

        # Just in case an async action is not yet complete
        Support::WaitForRequests.wait_for_requests(skip_finished_loading_check: skip_finished_loading_check,
          skip_resp_code_check: skip_resp_code_check)

        Support::Retrier.retry_until do
          visit(web_url)
          wait_until { current_url.include?(URI.parse(web_url).path.split('/').last || web_url) }
        end

        # Wait until the new page is ready for us to interact with it
        Support::WaitForRequests.wait_for_requests(skip_finished_loading_check: skip_finished_loading_check,
          skip_resp_code_check: skip_resp_code_check)
      end

      def populate(*attribute_names)
        attribute_names.each { |attribute_name| public_send(attribute_name) }
      end

      def wait_until(max_duration: 60, sleep_interval: 0.1, message: nil, &block)
        QA::Support::Waiter.wait_until(
          max_duration: max_duration, sleep_interval: sleep_interval, message: message, &block
        )
      end

      def retry_until(max_duration: 60, sleep_interval: 0.1, retry_on_exception: true, &block)
        Support::Retrier.retry_until(
          max_duration: max_duration,
          sleep_interval: sleep_interval,
          retry_on_exception: retry_on_exception,
          &block
        )
      end

      # Object comparison
      #
      # @param [QA::Resource::Base] other
      # @return [Boolean]
      def ==(other)
        other.is_a?(self.class) && comparable == other.comparable
      end

      # Override inspect for a better rspec failure diff output
      #
      # @return [String]
      def inspect
        JSON.pretty_generate(comparable)
      end

      def diff(other)
        return if self == other

        (comparable.to_a - other.comparable.to_a).to_h
      end

      def identifier
        if respond_to?(:username) && username
          "with username '#{username}'"
        elsif respond_to?(:full_path) && full_path
          "with full_path '#{full_path}'"
        elsif respond_to?(:name) && name
          "with name '#{name}'"
        elsif respond_to?(:id) && id
          "with id '#{id}'"
        elsif respond_to?(:iid) && iid
          "with iid '#{iid}'"
        end
      rescue QA::Resource::Base::NoValueError
        nil
      end

      def remove_via_api!
        super

        Runtime::Logger.info(["Removed a #{self.class.name}", identifier].compact.join(' '))
      end

      protected

      # Custom resource comparison logic using resource attributes from api_resource
      #
      # @return [Hash]
      def comparable
        raise("comparable method needs to be implemented in order to compare resources via '=='")
      end

      private

      def attribute_value(name, block)
        no_api_value = !api_resource&.key?(name)
        raise NoValueError, "No value was computed for #{name} of #{self.class.name}." if no_api_value && !block

        unless no_api_value
          api_value = api_resource[name]
          log_having_both_api_result_and_block(name, api_value) if block
          return api_value
        end

        instance_exec(&block)
      end

      # Get all defined attributes across all parents
      #
      # @return [Array<Symbol>]
      def all_attributes
        @all_attributes ||= self.class.ancestors
                                .select { |clazz| clazz <= QA::Resource::Base }
                                .map { |clazz| clazz.instance_variable_get(:@attribute_names) } # rubocop:disable Performance/FlatMap
                                .flatten
                                .compact
      end

      def log_having_both_api_result_and_block(name, api_value)
        api_value = "[MASKED]" if name == :token

        QA::Runtime::Logger.debug(<<~MSG.strip)
          <#{self.class}> Attribute #{name.inspect} has both API response `#{api_value}` and a block. API response will be picked. Block will be ignored.
        MSG
      end

      def api_delete_body; end
    end
  end
end
