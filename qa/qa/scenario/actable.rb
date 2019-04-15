# frozen_string_literal: true

module QA
  module Scenario
    module Actable
      def act(*args, &block)
        instance_exec(*args, &block)
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def perform
          yield new if block_given?
        end

        def act(*args, &block)
          new.act(*args, &block)
        end
      end
    end
  end
end
