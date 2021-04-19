# frozen_string_literal: true

module Gitlab
  ##
  # This class is a queuing system for processing expensive tasks in an atomic manner
  # with batch poping to let you optimize the total processing time.
  #
  # In usual queuing system, the first item started being processed immediately
  # and the following items wait until the next items have been popped from the queue.
  # On the other hand, this queueing system, the former part is same, however,
  # it pops the enqueued items as batch. This is especially useful when you want to
  # drop redundant items from the queue in order to process important items only,
  # thus it's more efficient than the traditional queueing system.
  #
  # Caveats:
  # - The order of the items are not guaranteed because of `sadd` (Redis Sets).
  #
  # Example:
  # ```
  # class TheWorker
  #   def perform
  #     result = Gitlab::BatchPopQueueing.new('feature', 'queue').safe_execute([item]) do |items_in_queue|
  #       item = extract_the_most_important_item_from(items_in_queue)
  #       expensive_process(item)
  #     end
  #
  #     if result[:status] == :finished && result[:new_items].present?
  #       item = extract_the_most_important_item_from(items_in_queue)
  #       TheWorker.perform_async(item.id)
  #     end
  #   end
  # end
  # ```
  #
  class BatchPopQueueing
    attr_reader :namespace, :queue_id

    EXTRA_QUEUE_EXPIRE_WINDOW = 1.hour
    MAX_COUNTS_OF_POP_ALL = 1000

    # Initialize queue
    #
    # @param [String] namespace The namespace of the exclusive lock and queue key. Typically, it's a feature name.
    # @param [String] queue_id The identifier of the queue.
    # @return [Boolean]
    def initialize(namespace, queue_id)
      raise ArgumentError if namespace.empty? || queue_id.empty?

      @namespace = namespace
      @queue_id = queue_id
    end

    ##
    # Execute the given block in an exclusive lock.
    # If there is the other thread has already working on the block,
    # it enqueues the items without processing the block.
    #
    # @param [Array<String>] new_items New items to be added to the queue.
    # @param [Time] lock_timeout The timeout of the exclusive lock. Generally, this value should be longer than the maximum prosess timing of the given block.
    # @return [Hash]
    #   - status => One of the `:enqueued` or `:finished`.
    #   - new_items => Newly enqueued items during the given block had been processed.
    #
    # NOTE: If an exception is raised in the block, the poppped items will not be recovered.
    #       We should NOT re-enqueue the items in this case because it could end up in an infinite loop.
    def safe_execute(new_items, lock_timeout: 10.minutes, &block)
      enqueue(new_items, lock_timeout + EXTRA_QUEUE_EXPIRE_WINDOW)

      lease = Gitlab::ExclusiveLease.new(lock_key, timeout: lock_timeout)

      return { status: :enqueued } unless uuid = lease.try_obtain

      begin
        all_args = pop_all

        yield all_args if block_given?

        { status: :finished, new_items: peek_all }
      ensure
        Gitlab::ExclusiveLease.cancel(lock_key, uuid)
      end
    end

    private

    def lock_key
      @lock_key ||= "batch_pop_queueing:lock:#{namespace}:#{queue_id}"
    end

    def queue_key
      @queue_key ||= "batch_pop_queueing:queue:#{namespace}:#{queue_id}"
    end

    def enqueue(items, expire_time)
      Gitlab::Redis::Queues.with do |redis|
        redis.sadd(queue_key, items)
        redis.expire(queue_key, expire_time.to_i)
      end
    end

    def pop_all
      Gitlab::Redis::Queues.with do |redis|
        redis.spop(queue_key, MAX_COUNTS_OF_POP_ALL)
      end
    end

    def peek_all
      Gitlab::Redis::Queues.with do |redis|
        redis.smembers(queue_key)
      end
    end
  end
end
