# frozen_string_literal: true

require 'forwardable'
require 'capybara/dsl'
require 'active_support/core_ext/array/extract_options'

module QA
  module Resource
    class Base
      extend SingleForwardable
      include ApiFabricator
      extend Capybara::DSL

      NoValueError = Class.new(RuntimeError)

      def_delegators :evaluator, :attribute

      def self.fabricate!(*args, &prepare_block)
        fabricate_via_api!(*args, &prepare_block)
      rescue NotImplementedError
        fabricate_via_browser_ui!(*args, &prepare_block)
      end

      def self.fabricate_via_browser_ui!(*args, &prepare_block)
        options = args.extract_options!
        resource = options.fetch(:resource) { new }
        parents = options.fetch(:parents) { [] }

        do_fabricate!(resource: resource, prepare_block: prepare_block, parents: parents) do
          log_fabrication(:browser_ui, resource, parents, args) { resource.fabricate!(*args) }

          current_url
        end
      end

      def self.fabricate_via_api!(*args, &prepare_block)
        options = args.extract_options!
        resource = options.fetch(:resource) { new }
        parents = options.fetch(:parents) { [] }

        raise NotImplementedError unless resource.api_support?

        resource.eager_load_api_client!

        do_fabricate!(resource: resource, prepare_block: prepare_block, parents: parents) do
          log_fabrication(:api, resource, parents, args) { resource.fabricate_via_api! }
        end
      end

      def self.remove_via_api!(*args, &prepare_block)
        options = args.extract_options!
        resource = options.fetch(:resource) { new }
        parents = options.fetch(:parents) { [] }

        resource.eager_load_api_client!

        do_fabricate!(resource: resource, prepare_block: prepare_block, parents: parents) do
          log_fabrication(:api, resource, parents, args) { resource.remove_via_api! }
        end
      end

      def fabricate!(*_args)
        raise NotImplementedError
      end

      def visit!
        Runtime::Logger.debug(%Q[Visiting #{self.class.name} at "#{web_url}"])

        Support::Retrier.retry_until do
          visit(web_url)
          wait { current_url.include?(URI.parse(web_url).path.split('/').last || web_url) }
        end
      end

      def populate(*attributes)
        attributes.each(&method(:public_send))
      end

      def wait(max: 60, interval: 0.1)
        QA::Support::Waiter.wait(max: max, interval: interval) do
          yield
        end
      end

      private

      def populate_attribute(name, block)
        value = attribute_value(name, block)

        raise NoValueError, "No value was computed for #{name} of #{self.class.name}." unless value

        value
      end

      def attribute_value(name, block)
        api_value = api_resource&.dig(name)

        if api_value && block
          log_having_both_api_result_and_block(name, api_value)
        end

        api_value || (block && instance_exec(&block))
      end

      def log_having_both_api_result_and_block(name, api_value)
        QA::Runtime::Logger.info "<#{self.class}> Attribute #{name.inspect} has both API response `#{api_value}` and a block. API response will be picked. Block will be ignored."
      end

      def self.do_fabricate!(resource:, prepare_block:, parents: [])
        prepare_block.call(resource) if prepare_block

        resource_web_url = yield
        resource.web_url = resource_web_url

        resource
      end
      private_class_method :do_fabricate!

      def self.log_fabrication(method, resource, parents, args)
        return yield unless Runtime::Env.debug?

        start = Time.now
        prefix = "==#{'=' * parents.size}>"
        msg = [prefix]
        msg << "Built a #{name}"
        msg << "as a dependency of #{parents.last}" if parents.any?
        msg << "via #{method}"

        yield.tap do
          msg << "in #{Time.now - start} seconds"
          puts msg.join(' ')
          puts if parents.empty?
        end
      end
      private_class_method :log_fabrication

      def self.evaluator
        @evaluator ||= Base::DSL.new(self)
      end
      private_class_method :evaluator

      class DSL
        def initialize(base)
          @base = base
        end

        def attribute(name, &block)
          @base.module_eval do
            attr_writer(name)

            define_method(name) do
              instance_variable_get("@#{name}") ||
                instance_variable_set(
                  "@#{name}",
                  populate_attribute(name, block))
            end
          end
        end
      end

      attribute :web_url
    end
  end
end
