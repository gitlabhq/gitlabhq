FactoryBot.define do
  factory :ci_build_trace_chunk, class: Ci::BuildTraceChunk do
    build factory: :ci_build
    chunk_index 0
    data_store :redis

    trait :redis_with_data do
      data_store :redis

      transient do
        initial_data 'test data'
      end

      after(:create) do |build_trace_chunk, evaluator|
        Gitlab::Redis::SharedState.with do |redis|
          redis.set(
            "gitlab:ci:trace:#{build_trace_chunk.build.id}:chunks:#{build_trace_chunk.chunk_index.to_i}",
            evaluator.initial_data,
            ex: 1.day)
        end
      end
    end

    trait :redis_without_data do
      data_store :redis
    end

    trait :database_with_data do
      data_store :database

      transient do
        initial_data 'test data'
      end

      after(:build) do |build_trace_chunk, evaluator|
        build_trace_chunk.raw_data = evaluator.initial_data
      end
    end

    trait :database_without_data do
      data_store :database
    end

    trait :fog_with_data do
      data_store :fog

      transient do
        initial_data 'test data'
      end

      after(:create) do |build_trace_chunk, evaluator|
        ::Fog::Storage.new(JobArtifactUploader.object_store_credentials).tap do |connection|
          connection.put_object(
            'artifacts',
            "tmp/builds/#{build_trace_chunk.build.id}/chunks/#{build_trace_chunk.chunk_index.to_i}.log",
            evaluator.initial_data)
        end
      end
    end

    trait :fog_without_data do
      data_store :fog
    end
  end
end
