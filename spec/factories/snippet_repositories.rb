# frozen_string_literal: true

FactoryBot.define do
  factory :snippet_repository do
    snippet

    after(:build) do |snippet_repository, _|
      snippet_repository.shard_name = snippet_repository.snippet.repository_storage
      snippet_repository.disk_path  = snippet_repository.snippet.disk_path
    end

    trait(:checksummed) do
      verification_checksum { 'abc' }
    end

    trait(:checksum_failure) do
      verification_failure { 'Could not calculate the checksum' }
    end
  end
end
