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
        do_fabricate!(prepare_block) do |factory|
          log_fabrication(:browser_ui, factory) { factory.fabricate!(*args) }

          current_url
        end
      end

      def self.fabricate_via_api!(*args, &prepare_block)
        do_fabricate!(prepare_block) do |factory|
          log_fabrication(:api, factory) { factory.fabricate_via_api! }
        end
      end

      def self.do_fabricate!(prepare_block)
        factory = new
        prepare_block.call(factory) if prepare_block

        dependencies.each do |signature|
          Factory::Dependency.new(factory, signature).build!
        end

        resource_web_url = yield(factory)

        Factory::Product.populate!(factory, resource_web_url)
      end
      private_class_method :do_fabricate!

      def self.log_fabrication(method, factory)
        start = Time.now

        yield.tap do
          puts "Resource #{factory.class.name} built via #{method} in #{Time.now - start} seconds" if Runtime::Env.verbose?
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
