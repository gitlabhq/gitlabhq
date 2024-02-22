# frozen_string_literal: true

module Backup
  module Tasks
    class Task
      attr_reader :progress, :options

      # Identifier used as parameter in the CLI to skip from executing
      def self.id
        raise NotImplementedError
      end

      def initialize(progress:, options:)
        @progress = progress
        @options = options
      end

      # Key string that identifies the task
      def id
        self.class.id
      end

      # Name of the task used for logging.
      def human_name
        raise NotImplementedError
      end

      # Where the task should put its backup file/dir
      def destination_path
        raise NotImplementedError
      end

      # The target factory method
      def target
        raise NotImplementedError
      end

      # Path to remove after a successful backup, uses #destination_path when not specified
      def cleanup_path
        destination_path
      end

      # `true` if the destination might not exist on a successful backup
      def destination_optional
        false
      end

      # `true` if the task can be used
      def enabled
        true
      end

      def enabled?
        enabled
      end
    end
  end
end
