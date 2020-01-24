# frozen_string_literal: true

module WorkerContext
  extend ActiveSupport::Concern

  class_methods do
    def worker_context(attributes)
      @worker_context = Gitlab::ApplicationContext.new(attributes)
    end

    def get_worker_context
      @worker_context || superclass_context
    end

    private

    def superclass_context
      return unless superclass.include?(WorkerContext)

      superclass.get_worker_context
    end
  end

  def with_context(context, &block)
    Gitlab::ApplicationContext.new(context).use(&block)
  end
end
