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
        do_fabricate!(prepare_block, *args) do |factory|
          if factory.api_support?
            log_fabrication(:do_fabricate_via_api, factory, *args)
          else
            log_fabrication(:do_fabricate_via_browser_ui, factory, *args)
          end
        end
      end

      def self.fabricate_via_browser_ui!(*args, &prepare_block)
        do_fabricate!(prepare_block, *args) do |factory|
          log_fabrication(:do_fabricate_via_browser_ui, factory, *args)
        end
      end

      def self.fabricate_via_api!(*args, &prepare_block)
        do_fabricate!(prepare_block, *args) do |factory|
          log_fabrication(:do_fabricate_via_api, factory, *args)
        end
      end

      def self.do_fabricate!(prepare_block, *args)
        new.tap do |factory|
          prepare_block.call(factory) if prepare_block

          dependencies.each do |signature|
            Factory::Dependency.new(factory, signature).build!
          end

          resource_web_url = yield(factory)

          break Factory::Product.populate!(factory, resource_web_url)
        end
      end

      def self.do_fabricate_via_browser_ui(factory, *args)
        factory.fabricate!(*args)

        current_url
      end

      def self.do_fabricate_via_api(factory, *_args)
        factory.fabricate_via_api!
      end

      def self.log_fabrication(method, factory, *args)
        start = Time.now

        public_send(method, factory, *args).tap do
          puts "Resource #{factory.class.name} built via #{method} in #{Time.now - start} seconds" if Runtime::Env.verbose?
        end
      end

      def self.evaluator
        @evaluator ||= Factory::Base::DSL.new(self)
      end

      class DSL
        attr_reader :dependencies, :attributes

        def initialize(base)
          @base = base
          @dependencies = []
          @attributes = {}
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
            @attributes.store(attribute, signature)
          end
        end
      end
    end
  end
end
