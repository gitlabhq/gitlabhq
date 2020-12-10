# frozen_string_literal: true

module Gitlab
  class BatchWorkerContext
    def initialize(objects, arguments_proc:, context_proc:)
      @objects = objects
      @arguments_proc = arguments_proc
      @context_proc = context_proc
    end

    def arguments
      context_by_arguments.keys
    end

    def context_for(arguments)
      context_by_arguments[arguments]
    end

    private

    attr_reader :objects, :arguments_proc, :context_proc

    def context_by_arguments
      @context_by_arguments ||= objects.each_with_object({}) do |object, result|
        arguments = Array.wrap(arguments_proc.call(object))
        context = Gitlab::ApplicationContext.new(**context_proc.call(object))

        result[arguments] = context
      end
    end
  end
end
