# frozen_string_literal: true

module WorkerContext
  extend ActiveSupport::Concern

  class_methods do
    def worker_context(attributes)
      @worker_context = Gitlab::ApplicationContext.new(**attributes)
    end

    def get_worker_context
      @worker_context || superclass_context
    end

    def bulk_perform_async_with_contexts(objects, arguments_proc:, context_proc:)
      with_batch_contexts(objects, arguments_proc, context_proc) do |arguments|
        bulk_perform_async(arguments)
      end
    end

    def bulk_perform_in_with_contexts(delay, objects, arguments_proc:, context_proc:)
      with_batch_contexts(objects, arguments_proc, context_proc) do |arguments|
        bulk_perform_in(delay, arguments)
      end
    end

    def context_for_arguments(args)
      batch_context&.context_for(args)
    end

    private

    BATCH_CONTEXT_KEY = "#{name}_batch_context"

    def batch_context
      Thread.current[BATCH_CONTEXT_KEY]
    end

    def batch_context=(value)
      Thread.current[BATCH_CONTEXT_KEY] = value
    end

    def with_batch_contexts(objects, arguments_proc, context_proc)
      self.batch_context = Gitlab::BatchWorkerContext.new(
        objects,
        arguments_proc: arguments_proc,
        context_proc: context_proc
      )

      yield(batch_context.arguments)
    ensure
      self.batch_context = nil
    end

    def superclass_context
      return unless superclass.include?(WorkerContext)

      superclass.get_worker_context
    end
  end

  def with_context(context, &block)
    Gitlab::ApplicationContext.new(**context).use { yield(**context) }
  end
end
