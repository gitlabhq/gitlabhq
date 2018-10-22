# frozen_string_literal: true

require 'forwardable'
require 'capybara/dsl'

module QA
  module Factory
    class Base
      extend SingleForwardable
      include ApiFabricator
      extend Capybara::DSL

      def_delegators :evaluator, :dependency, :dependencies
      def_delegators :evaluator, :product, :attributes

      def fabricate!(*_args)
        raise NotImplementedError
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

        dependencies.each do |signature|
          Factory::Dependency.new(factory, signature).build!(parents: parents + [self])
        end

        resource_web_url = yield

        Factory::Product.populate!(factory, resource_web_url)
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

      class DSL
        attr_reader :dependencies, :attributes

        def initialize(base)
          @base = base
          @dependencies = []
          @attributes = []
        end

        def dependency(factory, as:, &block)
          as.tap do |name|
            @base.class_eval { attr_accessor name }

            Dependency::Signature.new(name, factory, block).tap do |signature|
              @dependencies << signature
            end
          end
        end

        def product(attribute, &block)
          Product::Attribute.new(attribute, block).tap do |signature|
            @attributes << signature
          end
        end
      end
    end
  end
end
