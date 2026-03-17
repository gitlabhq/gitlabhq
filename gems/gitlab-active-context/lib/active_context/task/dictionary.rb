# frozen_string_literal: true

module ActiveContext
  module Task
    class Dictionary
      InvalidTaskNameError = Class.new(StandardError)

      class << self
        def instance
          @instance ||= new
        end

        def reset!
          @instance = nil
        end

        delegate :tasks, :find_by_name, to: :instance
      end

      def initialize
        @tasks = {}
      end

      def tasks
        @tasks.values
      end

      def find_by_name(name)
        @tasks[name.to_s] ||= load_task(name)
      end

      private

      def load_task(name)
        name.to_s.constantize
      rescue NameError
        raise InvalidTaskNameError, "Could not find task class '#{name}'"
      end
    end
  end
end
