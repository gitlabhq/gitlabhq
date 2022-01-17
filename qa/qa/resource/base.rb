# frozen_string_literal: true

require 'capybara/dsl'
require 'active_support/core_ext/array/extract_options'

module QA
  module Resource
    class Base
      include ApiFabricator
      extend Capybara::DSL

      NoValueError = Class.new(RuntimeError)

      class << self
        # Initialize new instance of class without fabrication
        #
        # @param [Proc] prepare_block
        def init(&prepare_block)
          new.tap(&prepare_block)
        end

        def fabricate!(*args, &prepare_block)
          fabricate_via_api!(*args, &prepare_block)
        rescue NotImplementedError
          fabricate_via_browser_ui!(*args, &prepare_block)
        end

        def fabricate_via_browser_ui!(*args, &prepare_block)
          options = args.extract_options!
          resource = options.fetch(:resource) { new }
          parents = options.fetch(:parents) { [] }

          do_fabricate!(resource: resource, prepare_block: prepare_block, parents: parents) do
            log_fabrication(:browser_ui, resource, parents, args) { resource.fabricate!(*args) }

            current_url
          end
        end

        def fabricate_via_api!(*args, &prepare_block)
          options = args.extract_options!
          resource = options.fetch(:resource) { new }
          parents = options.fetch(:parents) { [] }

          raise NotImplementedError unless resource.api_support?

          resource.eager_load_api_client!

          do_fabricate!(resource: resource, prepare_block: prepare_block, parents: parents) do
            log_fabrication(:api, resource, parents, args) { resource.fabricate_via_api! }
          end
        end

        def remove_via_api!(*args, &prepare_block)
          options = args.extract_options!
          resource = options.fetch(:resource) { new }
          parents = options.fetch(:parents) { [] }

          resource.eager_load_api_client!

          do_fabricate!(resource: resource, prepare_block: prepare_block, parents: parents) do
            log_fabrication(:api, resource, parents, args) { resource.remove_via_api! }
          end
        end

        private

        def do_fabricate!(resource:, prepare_block:, parents: [])
          prepare_block.call(resource) if prepare_block

          resource_web_url = yield
          resource.web_url = resource_web_url

          QA::Tools::TestResourceDataProcessor.collect(resource, resource_identifier(resource))

          resource
        end

        def resource_identifier(resource)
          if resource.respond_to?(:username) && resource.username
            "with username '#{resource.username}'"
          elsif resource.respond_to?(:full_path) && resource.full_path
            "with full_path '#{resource.full_path}'"
          elsif resource.respond_to?(:name) && resource.name
            "with name '#{resource.name}'"
          elsif resource.respond_to?(:id) && resource.id
            "with id '#{resource.id}'"
          elsif resource.respond_to?(:iid) && resource.iid
            "with iid '#{resource.iid}'"
          end
        rescue QA::Resource::Base::NoValueError
          nil
        end

        def log_fabrication(method, resource, parents, args)
          start = Time.now

          Support::FabricationTracker.start_fabrication
          result = yield.tap do
            fabrication_time = Time.now - start

            fabrication_http_method = if resource.api_fabrication_http_method == :get
                                        if self.include?(Reusable)
                                          "Retrieved for reuse"
                                        else
                                          "Retrieved"
                                        end
                                      else
                                        "Built"
                                      end

            Support::FabricationTracker.save_fabrication(:"#{method}_fabrication", fabrication_time)
            Runtime::Logger.debug do
              msg = ["==#{'=' * parents.size}>"]
              msg << "#{fabrication_http_method} a #{name}"
              msg << resource_identifier(resource) if resource_identifier(resource)
              msg << "as a dependency of #{parents.last}" if parents.any?
              msg << "via #{method}"
              msg << "in #{fabrication_time} seconds"

              msg.join(' ')
            end
          end
          Support::FabricationTracker.finish_fabrication

          result
        end

        # Define custom attribute
        #
        # @param [Symbol] name
        # @return [void]
        def attribute(name, &block)
          (@attribute_names ||= []).push(name) # save added attributes

          attr_writer(name)

          define_method(name) do
            return instance_variable_get("@#{name}") if instance_variable_defined?("@#{name}")

            instance_variable_set("@#{name}", attribute_value(name, block))
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

      # Override api reload! and update custom attributes from api_resource
      #
      api_reload = instance_method(:reload!)
      define_method(:reload!) do
        api_reload.bind_call(self)
        return self unless api_resource

        all_attributes.each do |attribute_name|
          instance_variable_set("@#{attribute_name}", api_resource[attribute_name]) if api_resource.key?(attribute_name)
        end

        self
      end

      attribute :web_url

      def fabricate!(*_args)
        raise NotImplementedError
      end

      def visit!(skip_resp_code_check: false)
        Runtime::Logger.debug(%(Visiting #{self.class.name} at "#{web_url}"))

        # Just in case an async action is not yet complete
        Support::WaitForRequests.wait_for_requests(skip_resp_code_check: skip_resp_code_check)

        Support::Retrier.retry_until do
          visit(web_url)
          wait_until { current_url.include?(URI.parse(web_url).path.split('/').last || web_url) }
        end

        # Wait until the new page is ready for us to interact with it
        Support::WaitForRequests.wait_for_requests(skip_resp_code_check: skip_resp_code_check)
      end

      def populate(*attribute_names)
        attribute_names.each { |attribute_name| public_send(attribute_name) }
      end

      def wait_until(max_duration: 60, sleep_interval: 0.1, &block)
        QA::Support::Waiter.wait_until(max_duration: max_duration, sleep_interval: sleep_interval, &block)
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
                                .map { |clazz| clazz.instance_variable_get(:@attribute_names) }
                                .flatten
                                .compact
      end

      def log_having_both_api_result_and_block(name, api_value)
        QA::Runtime::Logger.debug(<<~MSG.strip)
          <#{self.class}> Attribute #{name.inspect} has both API response `#{api_value}` and a block. API response will be picked. Block will be ignored.
        MSG
      end
    end
  end
end
