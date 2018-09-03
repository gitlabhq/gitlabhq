# frozen_string_literal: true

require 'airborne'
require 'forwardable'
require 'capybara/dsl'

module QA
  module Factory
    class Base
      extend SingleForwardable
      include Airborne
      include ApiFabricator
      extend Capybara::DSL

      def_delegators :evaluator, :dependency, :dependencies
      def_delegators :evaluator, :product, :attributes

      def fabricate!(*_args)
        raise NotImplementedError
      end

      def self.fabricate_via_api!(*args, &block)
        do_fabricate!(*args, block: block, via: :api)
      end

      def self.fabricate!(*args, &block)
        do_fabricate!(*args, block: block, via: :gui)
      end

      def self.do_fabricate!(*args, block: nil, via:)
        new.tap do |factory|
          block.call(factory) if block

          dependencies.each do |signature|
            Factory::Dependency.new(factory, signature).build!
          end

          start = Time.now
          resource_url =
            if via == :api && factory.api_support?
              factory.fabricate_via_api!(*args)
            else
              via = :gui
              factory.fabricate!(*args)
              current_url
            end

          puts "Resource #{factory.class.name} built via '#{via}' in #{Time.now - start} seconds" if Runtime::Env.verbose?

          break Factory::Product.populate!(factory, resource_url)
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
