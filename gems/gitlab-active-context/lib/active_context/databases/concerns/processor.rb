# frozen_string_literal: true

module ActiveContext
  module Databases
    module Concerns
      # Concern for processors that transform Query AST nodes into database-specific queries.
      #
      # @example Implementation
      #   class MyProcessor
      #     include ActiveContext::Databases::Concerns::Processor
      #
      #     def self.transform(node)
      #       new.process(node)
      #     end
      #
      #     def process(node)
      #       # Transform the node into a database-specific query
      #     end
      #   end
      module Processor
        extend ActiveSupport::Concern

        included do
          # @abstract Implement #process in subclass to transform query nodes
          def process(_node)
            raise NotImplementedError, "#{self.class.name} must implement #process"
          end
        end

        class_methods do
          # @abstract Implement .transform in subclass to handle query transformation
          def transform(_node)
            raise NotImplementedError, "#{name} must implement .transform"
          end
        end
      end
    end
  end
end
