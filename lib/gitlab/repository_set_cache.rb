# frozen_string_literal: true

# Interface to the Redis-backed cache store for keys that use a Redis set
module Gitlab
  class RepositorySetCache < Gitlab::SetCache
    attr_reader :repository, :namespace, :expires_in

    def initialize(repository, extra_namespace: nil, expires_in: 2.weeks)
      @repository = repository
      @namespace = "#{repository.full_path}"
      @namespace += ":#{repository.project.id}" if repository.project
      @namespace = "#{@namespace}:#{extra_namespace}" if extra_namespace
      @expires_in = expires_in
    end

    def cache_key(type)
      "#{type}:#{namespace}:set"
    end

    def write(key, value)
      full_key = cache_key(key)

      with do |redis|
        redis.multi do
          redis.unlink(full_key)

          # Splitting into groups of 1000 prevents us from creating a too-long
          # Redis command
          value.each_slice(1000) { |subset| redis.sadd(full_key, subset) }

          redis.expire(full_key, expires_in)
        end
      end

      value
    end

    def fetch(key, &block)
      if exist?(key)
        read(key)
      else
        write(key, yield)
      end
    end
  end
end
