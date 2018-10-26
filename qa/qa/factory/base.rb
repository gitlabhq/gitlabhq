# frozen_string_literal: true

require 'forwardable'
require 'capybara/dsl'

module QA
  module Factory
    class Base
      extend SingleForwardable
      include ApiFabricator
      extend Capybara::DSL

      NoValueError = Class.new(RuntimeError)

      def_delegators :evaluator, :attribute

      def fabricate!(*_args)
        raise NotImplementedError
      end

      def visit!
        visit(web_url)
      end

      private

      def populate_attribute(name, block)
        value = attribute_value(name, block)

        raise NoValueError, "No value was computed for product #{name} of factory #{self.class.name}." unless value

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

      def self.fabricate!(*args, &prepare_block)
        fabricate_via_api!(*args, &prepare_block)
      rescue NotImplementedError
        fabricate_via_browser_ui!(*args, &prepare_block)
      end

      def self.fabricate_via_browser_ui!(*args, &prepare_block)
        options = args.extract_options!
        factory = options.fetch(:factory) { new }
        parents = options.fetch(:parents) { [] }

        do_fabricate!(factory: factory, prepare_block: prepare_block, parents: parents) do
          log_fabrication(:browser_ui, factory, parents, args) { factory.fabricate!(*args) }

          current_url
        end
      end

      def self.fabricate_via_api!(*args, &prepare_block)
        options = args.extract_options!
        factory = options.fetch(:factory) { new }
        parents = options.fetch(:parents) { [] }

        raise NotImplementedError unless factory.api_support?

        factory.eager_load_api_client!

        do_fabricate!(factory: factory, prepare_block: prepare_block, parents: parents) do
          log_fabrication(:api, factory, parents, args) { factory.fabricate_via_api! }
        end
      end

      def self.do_fabricate!(factory:, prepare_block:, parents: [])
        prepare_block.call(factory) if prepare_block

        resource_web_url = yield
        factory.web_url = resource_web_url

        Factory::Product.new(factory)
      end
      private_class_method :do_fabricate!

      def self.log_fabrication(method, factory, parents, args)
        return yield unless Runtime::Env.debug?

        start = Time.now
        prefix = "==#{'=' * parents.size}>"
        msg = [prefix]
        msg << "Built a #{name}"
        msg << "as a dependency of #{parents.last}" if parents.any?
        msg << "via #{method} with args #{args}"

        yield.tap do
          msg << "in #{Time.now - start} seconds"
          puts msg.join(' ')
          puts if parents.empty?
        end
      end
      private_class_method :log_fabrication

      def self.evaluator
        @evaluator ||= Factory::Base::DSL.new(self)
      end
      private_class_method :evaluator

      def self.dynamic_attributes
        const_get(:DynamicAttributes)
      rescue NameError
        mod = const_set(:DynamicAttributes, Module.new)

        include mod

        mod
      end

      def self.attributes_names
        dynamic_attributes.instance_methods(false).sort.grep_v(/=$/)
      end

      class DSL
        def initialize(base)
          @base = base
        end

        def attribute(name, &block)
          @base.dynamic_attributes.module_eval do
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
