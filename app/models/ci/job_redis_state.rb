# frozen_string_literal: true

module Ci
  class JobRedisState
    include ActiveModel::Model
    include ActiveModel::Attributes

    class RedisBool < ::ActiveRecord::Type::Value
      def deserialize(value)
        ::Gitlab::Redis::Boolean.decode(value)
      end

      def serialize(value)
        ::Gitlab::Redis::Boolean.encode(value)
      end
    end

    UnpersistedJobError = Class.new(StandardError)

    REDIS_TTL = 300
    REDIS_KEY = "ci_job_redis_state:{%{project_id}}:%{job_id}"

    attribute :enqueue_immediately, RedisBool.new, default: false

    def self.find_or_initialize_by(job:)
      with_redis do |redis|
        redis_attributes = redis.hgetall(redis_key(job.project_id, job.id))
        deserialized_attrs = redis_attributes.each.with_object({}) do |(key, value), result|
          result[key] = attribute_types[key].deserialize(value)
        end

        new(deserialized_attrs.merge(job: job))
      end
    end

    def self.redis_key(project_id, job_id)
      format(REDIS_KEY, project_id: project_id, job_id: job_id)
    end

    def self.with_redis(&block)
      ::Gitlab::Redis::SharedState.with(&block)
    end

    def initialize(attributes = {})
      @job = attributes.delete(:job)
      super
    end

    # We need a job_id to save the record in Redis
    def save
      raise UnpersistedJobError unless job.persisted?

      with_redis do |redis|
        redis.multi do |transaction|
          transaction.hset(redis_key, attributes_for_redis)
          transaction.expire(redis_key, REDIS_TTL)
        end
      end

      true
    end

    def update(values = {})
      assign_attributes(values)
      save
    end

    def enqueue_immediately?
      enqueue_immediately
    end

    private

    attr_reader :job

    delegate :with_redis, to: :class

    def attributes_for_redis
      @attributes.values_for_database
    end

    def redis_key
      @redis_key ||= self.class.redis_key(job.project_id, job.id)
    end
  end
end
