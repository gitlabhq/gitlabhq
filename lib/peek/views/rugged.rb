# frozen_string_literal: true

module Peek
  module Views
    class Rugged < DetailedView
      def results
        return {} unless calls > 0

        super
      end

      private

      def duration
        ::Gitlab::RuggedInstrumentation.query_time
      end

      def calls
        ::Gitlab::RuggedInstrumentation.query_count
      end

      def call_details
        ::Gitlab::RuggedInstrumentation.list_call_details
      end

      def format_call_details(call)
        super.merge(args: format_args(call[:args]))
      end

      def format_args(args)
        args.map do |arg|
          # ActiveSupport::JSON recursively calls as_json on all
          # instance variables, and if that instance variable points to
          # something that refers back to the same instance, we can wind
          # up in an infinite loop. Currently this only seems to happen with
          # Gitlab::Git::Repository and ::Repository.
          if arg.instance_variables.present?
            arg.to_s
          else
            arg
          end
        end
      end
    end
  end
end
