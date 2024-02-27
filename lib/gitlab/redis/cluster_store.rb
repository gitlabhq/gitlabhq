# frozen_string_literal: true

require 'redis-clustering'
require 'redis/store/ttl'
require 'redis/store/interface'
require 'redis/store/namespace'
require 'redis/store/serialization'

module Gitlab
  module Redis
    class ClusterStore < ::Redis::Cluster
      include ::Redis::Store::Interface

      def initialize(options = {})
        orig_options = options.dup

        @serializer = orig_options.key?(:serializer) ? orig_options.delete(:serializer) : Marshal

        unless orig_options[:marshalling].nil?
          # `marshalling` only used here, might not be supported in `super`
          @serializer = orig_options.delete(:marshalling) ? Marshal : nil
        end

        _remove_unsupported_options(options)
        super(options)

        _extend_marshalling
        _extend_namespace orig_options
      end

      # copies ::Redis::Store::Ttl implementation in a redis-v5 compatible manner
      def set(key, value, options = nil)
        ttl = get_ttl(options)
        if ttl
          setex(key, ttl.to_i, value, raw: true)
        else
          super(key, value)
        end
      end

      # copies ::Redis::Store::Ttl implementation in a redis-v5 compatible manner
      def setnx(key, value, options = nil)
        ttl = get_ttl(options)
        if ttl
          multi do |m|
            m.setnx(key, value)
            m.expire(key, ttl)
          end
        else
          super(key, value)
        end
      end

      private

      def get_ttl(options)
        # https://github.com/redis-store/redis-store/blob/v1.10.0/lib/redis/store/ttl.rb#L37
        options[:expire_after] || options[:expires_in] || options[:expire_in] if options
      end

      def _remove_unsupported_options(options)
        # Unsupported keywords should be removed to avoid errors
        # https://github.com/redis-rb/redis-client/blob/v0.13.0/lib/redis_client/config.rb#L21
        options.delete(:raw)
        options.delete(:serializer)
        options.delete(:marshalling)
        options.delete(:namespace)
        options.delete(:scheme)
      end

      def _extend_marshalling
        extend ::Redis::Store::Serialization unless @serializer.nil?
      end

      def _extend_namespace(options)
        @namespace = options[:namespace]
        extend ::Redis::Store::Namespace
      end
    end
  end
end
