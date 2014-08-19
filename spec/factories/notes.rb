require_relative '../support/repo_helpers'

FactoryGirl.define do
  factory :note do
    project
    note "Note"
    author

    factory :note_on_commit, traits: [:on_commit]
    factory :note_on_commit_diff, traits: [:on_commit, :on_diff]
    factory :note_on_issue, traits: [:on_issue], aliases: [:votable_note]
    factory :note_on_merge_request, traits: [:on_merge_request]
    factory :note_on_merge_request_diff, traits: [:on_merge_request, :on_diff]

    trait :on_commit do
      project factory: :project
      commit_id RepoHelpers.sample_commit.id
      noteable_type "Commit"
    end

    trait :on_diff do
      line_code "0_184_184"
    end

    trait :on_merge_request do
      project factory: :project
      noteable_id 1
      noteable_type "MergeRequest"
    end

    trait :on_issue do
      noteable_id 1
      noteable_type "Issue"
    end

    trait :with_attachment do
      attachment { fixture_file_upload(Rails.root + "spec/fixtures/dk.png", "`/png") }
    end
  end
end
