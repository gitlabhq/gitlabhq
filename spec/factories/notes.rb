require_relative '../support/repo_helpers'

include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :note do
    project
    note "Note"
    author
    noteable { create(:issue, project: project) }

    factory :note_on_commit,             traits: [:on_commit]
    factory :note_on_commit_diff,        traits: [:on_commit, :on_diff], class: LegacyDiffNote
    factory :note_on_issue,              traits: [:on_issue], aliases: [:votable_note]
    factory :note_on_merge_request,      traits: [:on_merge_request]
    factory :note_on_merge_request_diff, traits: [:on_merge_request, :on_diff], class: LegacyDiffNote
    factory :note_on_project_snippet,    traits: [:on_project_snippet]
    factory :system_note,                traits: [:system]
    factory :downvote_note,              traits: [:award, :downvote]
    factory :upvote_note,                traits: [:award, :upvote]

    trait :on_commit do
      noteable nil
      noteable_type 'Commit'
      noteable_id nil
      commit_id RepoHelpers.sample_commit.id
    end

    trait :on_diff do
      line_code "0_184_184"
    end

    trait :on_issue do
      noteable_type 'Issue'
      noteable { create(:issue, project: project) }
    end

    trait :on_merge_request do
      noteable_type 'MergeRequest'
      noteable do
        create(:merge_request, source_project: project,
                               target_project: project)
      end
    end

    trait :on_project_snippet do
      noteable_type 'Snippet'
      noteable { create(:snippet, project: project) }
    end

    trait :system do
      system true
    end

    trait :award do
      is_award true
    end

    trait :downvote do
      note "thumbsdown"
    end

    trait :upvote do
      note "thumbsup"
    end

    trait :with_attachment do
      attachment { fixture_file_upload(Rails.root + "spec/fixtures/dk.png", "`/png") }
    end
  end
end
