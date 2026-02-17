# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_diff_commit do
    association :merge_request_diff

    relative_order { 0 }

    transient do
      commit_author { association(:merge_request_diff_commit_user) }
      committer { association(:merge_request_diff_commit_user) }
      merge_request_commits_metadata { nil }
      authored_date { nil }
      committed_date { nil }
      sha { nil }
      message { nil }
    end

    after(:build) do |merge_request_diff_commit, evaluator|
      # rubocop:disable RSpec/FactoryBot/StrategyInCallback -- We need to create
      # an associated `merge_request_commits_metadata` when we build/create a
      # `merge_request_diff_commit` to replicate how data is created in bulk
      # creation.
      existing_metadata =
        evaluator.merge_request_commits_metadata.presence ||
        MergeRequest::CommitsMetadata.find_by(project_id: evaluator.merge_request_diff.project_id, sha: evaluator.sha)

      metadata = existing_metadata || create(
        :merge_request_commits_metadata,
        project: merge_request_diff_commit.merge_request_diff.project,
        sha: evaluator.sha || OpenSSL::Digest::SHA256.hexdigest(SecureRandom.hex),
        commit_author: evaluator.commit_author,
        committer: evaluator.committer,
        authored_date: evaluator.authored_date,
        committed_date: evaluator.committed_date,
        message: evaluator.message
      )

      merge_request_diff_commit.merge_request_commits_metadata_id = metadata.id
      # rubocop:enable RSpec/FactoryBot/StrategyInCallback
    end

    trait :with_duplicated_data do
      after(:create) do |merge_request_diff_commit|
        metadata = merge_request_diff_commit.merge_request_commits_metadata

        merge_request_diff_commit.update_columns(
          sha: metadata.sha,
          commit_author_id: metadata.commit_author_id,
          committer_id: metadata.committer_id,
          authored_date: metadata.authored_date,
          committed_date: metadata.committed_date,
          message: metadata.message
        )
      end
    end
  end

  factory :diff_commit_without_metadata, class: 'MergeRequestDiffCommit' do
    association :merge_request_diff

    relative_order { 0 }

    sha { OpenSSL::Digest::SHA256.hexdigest(SecureRandom.hex) }
  end
end
