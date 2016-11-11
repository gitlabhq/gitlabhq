require_relative '../support/repo_helpers'

include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :note do
    project
    note "Note"
    author
    on_issue

    factory :note_on_commit,             traits: [:on_commit]
    factory :note_on_issue,              traits: [:on_issue], aliases: [:votable_note]
    factory :note_on_merge_request,      traits: [:on_merge_request]
    factory :note_on_project_snippet,    traits: [:on_project_snippet]
    factory :system_note,                traits: [:system]

    factory :legacy_diff_note_on_commit, traits: [:on_commit, :legacy_diff_note], class: LegacyDiffNote
    factory :legacy_diff_note_on_merge_request, traits: [:on_merge_request, :legacy_diff_note], class: LegacyDiffNote

    factory :diff_note_on_merge_request, traits: [:on_merge_request], class: DiffNote do
      position do
        Gitlab::Diff::Position.new(
          old_path: "files/ruby/popen.rb",
          new_path: "files/ruby/popen.rb",
          old_line: nil,
          new_line: 14,
          diff_refs: noteable.diff_refs
        )
      end

      trait :resolved do
        resolved_at { Time.now }
        resolved_by { create(:user) }
      end
    end

    factory :diff_note_on_commit, traits: [:on_commit], class: DiffNote do
      position do
        Gitlab::Diff::Position.new(
          old_path: "files/ruby/popen.rb",
          new_path: "files/ruby/popen.rb",
          old_line: nil,
          new_line: 14,
          diff_refs: project.commit(commit_id).try(:diff_refs)
        )
      end
    end

    trait :on_commit do
      noteable nil
      noteable_type 'Commit'
      noteable_id nil
      commit_id RepoHelpers.sample_commit.id
    end

    trait :legacy_diff_note do
      line_code "0_184_184"
    end

    trait :on_issue do
      noteable { create(:issue, project: project) }
    end

    trait :on_merge_request do
      noteable { create(:merge_request, source_project: project) }
    end

    trait :on_project_snippet do
      noteable { create(:snippet, project: project) }
    end

    trait :system do
      system true
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
