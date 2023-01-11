# frozen_string_literal: true

module Gitlab
  module Redis
    class MultiStore
      include Gitlab::Utils::StrongMemoize

      class ReadFromPrimaryError < StandardError
        def message
          'Value not found on the redis primary store. Read from the redis secondary store successful.'
        end
      end

      class PipelinedDiffError < StandardError
        def initialize(result_primary, result_secondary)
          @result_primary = result_primary
          @result_secondary = result_secondary
        end

        def message
          "Pipelined command executed on both stores successfully but results differ between them. " \
            "Result from the primary: #{@result_primary.inspect}. " \
            "Result from the secondary: #{@result_secondary.inspect}."
        end
      end

      class MethodMissingError < StandardError
        def message
          'Method missing. Falling back to execute method on the redis default store in Rails.env.production.'
        end
      end

      attr_reader :primary_store, :secondary_store, :instance_name

      FAILED_TO_READ_ERROR_MESSAGE = 'Failed to read from the redis primary_store.'
      FAILED_TO_WRITE_ERROR_MESSAGE = 'Failed to write to the redis primary_store.'
      FAILED_TO_RUN_PIPELINE = 'Failed to execute pipeline on the redis primary_store.'

      SKIP_LOG_METHOD_MISSING_FOR_COMMANDS = %i[info].freeze

      # For ENUMERATOR_CACHE_HIT_VALIDATOR and READ_CACHE_HIT_VALIDATOR,
      # we define procs to validate cache hit. The only other acceptable value is nil,
      # in the case of errors being raised.
      #
      # If a command has no empty response, set ->(val) { true }
      #
      # Ref: https://www.rubydoc.info/github/redis/redis-rb/Redis/Commands
      #
      ENUMERATOR_CACHE_HIT_VALIDATOR = {
        scan_each: ->(val) { val.is_a?(Enumerator) && !val.first.nil? },
        hscan_each: ->(val) { val.is_a?(Enumerator) && !val.first.nil? },
        sscan_each: ->(val) { val.is_a?(Enumerator) && !val.first.nil? },
        zscan_each: ->(val) { val.is_a?(Enumerator) && !val.first.nil? }
      }.freeze

      READ_CACHE_HIT_VALIDATOR = {
        exists: ->(val) { val != 0 },
        exists?: ->(val) { val },
        get: ->(val) { !val.nil? },
        hexists: ->(val) { val },
        hget: ->(val) { !val.nil? },
        hgetall:  ->(val) { val.is_a?(Hash) && !val.empty? },
        hlen: ->(val) { val != 0 },
        hmget: ->(val) { val.is_a?(Array) && !val.compact.empty? },
        mapped_hmget: ->(val) { val.is_a?(Hash) && !val.compact.empty? },
        mget: ->(val) { val.is_a?(Array) && !val.compact.empty? },
        scard: ->(val) { val != 0 },
        sismember: ->(val) { val },
        smembers: ->(val) { val.is_a?(Array) && !val.empty? },
        sscan: ->(val) { val != ['0', []] },
        ttl: ->(val) { val != 0 && val != -2 }
      }.freeze

      WRITE_COMMANDS = %i[
        del
        eval
        expire
        flushdb
        hdel
        hset
        incr
        incrby
        mapped_hmset
        rpush
        sadd
        set
        setex
        setnx
        srem
        unlink
      ].freeze

      PIPELINED_COMMANDS = %i[
        pipelined
        multi
      ].freeze

      # To transition between two Redis store, `primary_store` should be the target store,
      # and `secondary_store` should be the current store. Transition is controlled with feature flags:
      #
      # - At the default state, all read and write operations are executed in the secondary instance.
      # - Turning use_primary_and_secondary_stores_for_<instance_name> on: The store writes to both instances.
      #   The read commands are executed in primary, but fallback to secondary.
      #   Other commands are executed in the the default instance (Secondary).
      # - Turning use_primary_store_as_default_for_<instance_name> on: The behavior is the same as above,
      #   but other commands are executed in the primary now.
      # - Turning use_primary_and_secondary_stores_for_<instance_name> off: commands are executed in the primary store.
      def initialize(primary_store, secondary_store, instance_name)
        @primary_store = primary_store
        @secondary_store = secondary_store
        @instance_name = instance_name

        validate_stores!
      end

      # rubocop:disable GitlabSecurity/PublicSend
      READ_CACHE_HIT_VALIDATOR.each_key do |name|
        define_method(name) do |*args, **kwargs, &block|
          if use_primary_and_secondary_stores?
            read_command(name, *args, **kwargs, &block)
          else
            default_store.send(name, *args, **kwargs, &block)
          end
        end
      end

      WRITE_COMMANDS.each do |name|
        define_method(name) do |*args, **kwargs, &block|
          if use_primary_and_secondary_stores?
            write_command(name, *args, **kwargs, &block)
          else
            default_store.send(name, *args, **kwargs, &block)
          end
        end
      end

      ENUMERATOR_CACHE_HIT_VALIDATOR.each_key do |name|
        define_method(name) do |*args, **kwargs, &block|
          enumerator = if use_primary_and_secondary_stores?
                         read_command(name, *args, **kwargs)
                       else
                         default_store.send(name, *args, **kwargs)
                       end

          return enumerator if block.nil?

          enumerator.each(&block)
        end
      end

      PIPELINED_COMMANDS.each do |name|
        define_method(name) do |*args, **kwargs, &block|
          if use_primary_and_secondary_stores?
            pipelined_both(name, *args, **kwargs, &block)
          else
            default_store.send(name, *args, **kwargs, &block)
          end
        end
      end

      def method_missing(...)
        return @instance.send(...) if @instance

        log_method_missing(...)

        default_store.send(...)
      end
      # rubocop:enable GitlabSecurity/PublicSend

      def respond_to_missing?(command_name, include_private = false)
        true
      end

      # This is needed because of Redis::Rack::Connection is requiring Redis::Store
      # https://github.com/redis-store/redis-rack/blob/a833086ba494083b6a384a1a4e58b36573a9165d/lib/redis/rack/connection.rb#L15
      # Done similarly in https://github.com/lsegal/yard/blob/main/lib/yard/templates/template.rb#L122
      def is_a?(klass)
        return true if klass == default_store.class

        super(klass)
      end
      alias_method :kind_of?, :is_a?

      def to_s
        use_primary_and_secondary_stores? ? primary_store.to_s : default_store.to_s
      end

      def use_primary_and_secondary_stores?
        feature_enabled?("use_primary_and_secondary_stores_for")
      end

      def use_primary_store_as_default?
        feature_enabled?("use_primary_store_as_default_for")
      end

      def increment_pipelined_command_error_count(command_name)
        @pipelined_command_error ||= Gitlab::Metrics.counter(:gitlab_redis_multi_store_pipelined_diff_error_total,
                                                             'Redis MultiStore pipelined command diff between stores')
        @pipelined_command_error.increment(command: command_name, instance_name: instance_name)
      end

      def increment_read_fallback_count(command_name)
        @read_fallback_counter ||= Gitlab::Metrics.counter(:gitlab_redis_multi_store_read_fallback_total,
                                                           'Client side Redis MultiStore reading fallback')
        @read_fallback_counter.increment(command: command_name, instance_name: instance_name)
      end

      def increment_method_missing_count(command_name)
        @method_missing_counter ||= Gitlab::Metrics.counter(:gitlab_redis_multi_store_method_missing_total,
                                                            'Client side Redis MultiStore method missing')
        @method_missing_counter.increment(command: command_name, instance_name: instance_name)
      end

      def log_error(exception, command_name, extra = {})
        Gitlab::ErrorTracking.log_exception(
          exception,
          extra.merge(command_name: command_name, instance_name: instance_name))
      end

      private

      # @return [Boolean]
      def feature_enabled?(prefix)
        feature_table_exists? &&
          Feature.enabled?("#{prefix}_#{instance_name.underscore}") && # rubocop:disable Cop/FeatureFlagUsage
          !same_redis_store?
      end

      # @return [Boolean]
      def feature_table_exists?
        Feature::FlipperFeature.table_exists?
      rescue StandardError
        false
      end

      def default_store
        use_primary_store_as_default? ? primary_store : secondary_store
      end

      def log_method_missing(command_name, *_args)
        return if SKIP_LOG_METHOD_MISSING_FOR_COMMANDS.include?(command_name)

        raise MethodMissingError if Rails.env.test? || Rails.env.development?

        log_error(MethodMissingError.new, command_name)
        increment_method_missing_count(command_name)
      end

      def read_command(command_name, *args, **kwargs, &block)
        if @instance
          send_command(@instance, command_name, *args, **kwargs, &block)
        else
          read_one_with_fallback(command_name, *args, **kwargs, &block)
        end
      end

      def write_command(command_name, *args, **kwargs, &block)
        if @instance
          send_command(@instance, command_name, *args, **kwargs, &block)
        else
          write_both(command_name, *args, **kwargs, &block)
        end
      end

      def read_one_with_fallback(command_name, *args, **kwargs, &block)
        begin
          value = send_command(primary_store, command_name, *args, **kwargs, &block)
        rescue StandardError => e
          log_error(e, command_name,
            multi_store_error_message: FAILED_TO_READ_ERROR_MESSAGE)
        end

        return value if cache_hit?(command_name, value)

        fallback_read(command_name, *args, **kwargs, &block)
      end

      def cache_hit?(command, value)
        validator = READ_CACHE_HIT_VALIDATOR[command] || ENUMERATOR_CACHE_HIT_VALIDATOR[command]
        return false unless validator

        !value.nil? && validator.call(value)
      end

      def fallback_read(command_name, *args, **kwargs, &block)
        value = send_command(secondary_store, command_name, *args, **kwargs, &block)

        if value
          log_error(ReadFromPrimaryError.new, command_name)
          increment_read_fallback_count(command_name)
        end

        value
      end

      def write_both(command_name, *args, **kwargs, &block)
        begin
          send_command(primary_store, command_name, *args, **kwargs, &block)
        rescue StandardError => e
          log_error(e, command_name,
            multi_store_error_message: FAILED_TO_WRITE_ERROR_MESSAGE)
        end

        send_command(secondary_store, command_name, *args, **kwargs, &block)
      end

      # Run the entire pipeline on both stores. We assume that `&block` is idempotent.
      def pipelined_both(command_name, *args, **kwargs, &block)
        begin
          result_primary = send_command(primary_store, command_name, *args, **kwargs, &block)
        rescue StandardError => e
          log_error(e, command_name, multi_store_error_message: FAILED_TO_RUN_PIPELINE)
        end

        result_secondary = send_command(secondary_store, command_name, *args, **kwargs, &block)

        # Pipelined commands return an array with all results. If they differ, log an error
        if result_primary && result_primary != result_secondary
          error = PipelinedDiffError.new(result_primary, result_secondary)
          error.set_backtrace(Thread.current.backtrace[1..]) # Manually set backtrace, since the error is not `raise`d

          log_error(error, command_name)
          increment_pipelined_command_error_count(command_name)
        end

        result_secondary
      end

      def same_redis_store?
        strong_memoize(:same_redis_store) do
          # <Redis client v4.7.1 for unix:///path_to/redis/redis.socket/5>"
          primary_store.inspect == secondary_store.inspect
        end
      end

      # rubocop:disable GitlabSecurity/PublicSend
      def send_command(redis_instance, command_name, *args, **kwargs, &block)
        if block
          # Make sure that block is wrapped and executed only on the redis instance that is executing the block
          redis_instance.send(command_name, *args, **kwargs) do |*params|
            with_instance(redis_instance, *params, &block)
          end
        else
          redis_instance.send(command_name, *args, **kwargs)
        end
      end
      # rubocop:enable GitlabSecurity/PublicSend

      def with_instance(instance, *params)
        @instance = instance

        yield(*params)
      ensure
        @instance = nil
      end

      def redis_store?(store)
        store.is_a?(::Redis) || store.is_a?(::Redis::Namespace)
      end

      def validate_stores!
        raise ArgumentError, 'primary_store is required' unless primary_store
        raise ArgumentError, 'secondary_store is required' unless secondary_store
        raise ArgumentError, 'instance_name is required' unless instance_name
        raise ArgumentError, 'invalid primary_store' unless redis_store?(primary_store)
        raise ArgumentError, 'invalid secondary_store' unless redis_store?(secondary_store)
      end
    end
  end
end
