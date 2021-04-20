# frozen_string_literal: true

# Interface to the Redis-backed cache store for keys that use a Redis HSET.
# This is currently used as an incremental cache by the `Repository` model
# for `#merged_branch_names`. It works slightly differently to the other
# repository cache classes in that it is intended to work with partial
# caches which can be updated with new data, using the Redis hash system.

module Gitlab
  class RepositoryHashCache
    attr_reader :repository, :namespace, :expires_in

    RepositoryHashCacheError = Class.new(StandardError)
    InvalidKeysProvidedError = Class.new(RepositoryHashCacheError)
    InvalidHashProvidedError = Class.new(RepositoryHashCacheError)

    # @param repository [Repository]
    # @param extra_namespace [String]
    # @param expires_in [Integer] expiry time for hash store keys
    def initialize(repository, extra_namespace: nil, expires_in: 1.day)
      @repository = repository
      @namespace = "#{repository.full_path}"
      @namespace += ":#{repository.project.id}" if repository.project
      @namespace = "#{@namespace}:#{extra_namespace}" if extra_namespace
      @expires_in = expires_in
    end

    # @param type [String]
    # @return [String]
    def cache_key(type)
      "#{type}:#{namespace}:hash"
    end

    # @param keys [String] one or multiple keys to delete
    # @return [Integer] the number of keys successfully deleted
    def delete(*keys)
      return 0 if keys.empty?

      with do |redis|
        keys = keys.map { |key| cache_key(key) }

        Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
          redis.unlink(*keys)
        end
      end
    end

    # Check if the provided hash key exists in the hash.
    #
    # @param key [String]
    # @param h_key [String] the key to check presence in Redis
    # @return [True, False]
    def key?(key, h_key)
      with { |redis| redis.hexists(cache_key(key), h_key) }
    end

    # Read the values of a set of keys from the hash store, and return them
    # as a hash of those keys and their values.
    #
    # @param key [String]
    # @param hash_keys [Array<String>] an array of keys to retrieve from the store
    # @return [Hash] a Ruby hash of the provided keys and their values from the store
    def read_members(key, hash_keys = [])
      raise InvalidKeysProvidedError unless hash_keys.is_a?(Array) && hash_keys.any?

      with do |redis|
        # Fetch an array of values for the supplied keys
        values = redis.hmget(cache_key(key), hash_keys)

        # Turn it back into a hash
        hash_keys.zip(values).to_h
      end
    end

    # Write a hash to the store. All keys and values will be strings when stored.
    #
    # @param key [String]
    # @param hash [Hash] the hash to be written to Redis
    # @return [Boolean] whether all operations were successful or not
    def write(key, hash)
      raise InvalidHashProvidedError unless hash.is_a?(Hash) && hash.any?

      full_key = cache_key(key)

      with do |redis|
        results = redis.pipelined do
          # Set each hash key to the provided value
          hash.each do |h_key, h_value|
            redis.hset(full_key, h_key, h_value)
          end

          # Update the expiry time for this hset
          redis.expire(full_key, expires_in)
        end

        results.all?
      end
    end

    # A variation on the `fetch` pattern of other cache stores. This method
    # allows you to attempt to fetch a group of keys from the hash store, and
    # for any keys that are missing values a block is then called to provide
    # those values, which are then written back into Redis. Both sets of data
    # are then combined and returned as one hash.
    #
    # @param key [String]
    # @param h_keys [Array<String>] the keys to fetch or add to the cache
    # @yieldparam missing_keys [Array<String>] the keys missing from the cache
    # @yieldparam new_values [Hash] the hash to be populated by the block
    # @return [Hash] the amalgamated hash of cached and uncached values
    def fetch_and_add_missing(key, h_keys, &block)
      # Check the cache for all supplied keys
      cache_values = read_members(key, h_keys)

      # Find the results which returned nil (meaning they're not in the cache)
      missing = cache_values.select { |_, v| v.nil? }.keys

      if missing.any?
        new_values = {}

        # Run the block, which updates the new_values hash
        yield(missing, new_values)

        # Ensure all values are converted to strings, to ensure merging hashes
        # below returns standardised data.
        new_values = standardize_hash(new_values)

        # Write the new values to the hset
        write(key, new_values)

        # Merge the two sets of values to return a complete hash
        cache_values.merge!(new_values)
      end

      record_metrics(key, cache_values, missing)

      cache_values
    end

    private

    def with(&blk)
      Gitlab::Redis::Cache.with(&blk) # rubocop:disable CodeReuse/ActiveRecord
    end

    # Take a hash and convert both keys and values to strings, for insertion into Redis.
    #
    # @param hash [Hash]
    # @return [Hash] the stringified hash
    def standardize_hash(hash)
      hash.to_h { |k, v| [k.to_s, v.to_s] }
    end

    # Record metrics in Prometheus.
    #
    # @param key [String] the basic key, e.g. :merged_branch_names. Not record-specific.
    # @param cache_values [Hash] the hash response from the cache read
    # @param missing_keys [Array<String>] the array of missing keys from the cache read
    def record_metrics(key, cache_values, missing_keys)
      cache_hits = cache_values.delete_if { |_, v| v.nil? }

      # Increment the counter if we have hits
      metrics_hit_counter.increment(full_hit: missing_keys.empty?, store_type: key) if cache_hits.any?

      # Track the number of hits we got
      metrics_hit_histogram.observe({ type: "hits", store_type: key }, cache_hits.size)
      metrics_hit_histogram.observe({ type: "misses", store_type: key }, missing_keys.size)
    end

    def metrics_hit_counter
      @counter ||= Gitlab::Metrics.counter(
        :gitlab_repository_hash_cache_hit,
        "Count of cache hits in Redis HSET"
      )
    end

    def metrics_hit_histogram
      @histogram ||= Gitlab::Metrics.histogram(
        :gitlab_repository_hash_cache_size,
        "Number of records in the HSET"
      )
    end
  end
end
