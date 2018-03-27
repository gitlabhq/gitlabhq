require_relative '../support/repo_helpers'

include ActionDispatch::TestProcess

FactoryBot.define do
  factory :note do
    project
    note { generate(:title) }
    author { project&.creator || create(:user) }
    on_issue

    factory :note_on_commit,             traits: [:on_commit]
    factory :note_on_issue,              traits: [:on_issue], aliases: [:votable_note]
    factory :note_on_merge_request,      traits: [:on_merge_request]
    factory :note_on_project_snippet,    traits: [:on_project_snippet]
    factory :note_on_personal_snippet,   traits: [:on_personal_snippet]
    factory :system_note,                traits: [:system]

    factory :discussion_note, class: DiscussionNote

    factory :discussion_note_on_merge_request, traits: [:on_merge_request], class: DiscussionNote do
      association :project, :repository

      trait :resolved do
        resolved_at { Time.now }
        resolved_by { create(:user) }
      end
    end

    factory :discussion_note_on_issue, traits: [:on_issue], class: DiscussionNote

    factory :discussion_note_on_commit, traits: [:on_commit], class: DiscussionNote

    factory :discussion_note_on_personal_snippet, traits: [:on_personal_snippet], class: DiscussionNote

    factory :discussion_note_on_snippet, traits: [:on_snippet], class: DiscussionNote

    factory :legacy_diff_note_on_commit, traits: [:on_commit, :legacy_diff_note], class: LegacyDiffNote

    factory :legacy_diff_note_on_merge_request, traits: [:on_merge_request, :legacy_diff_note], class: LegacyDiffNote do
      association :project, :repository
    end

    factory :diff_note_on_merge_request, traits: [:on_merge_request], class: DiffNote do
      association :project, :repository

      transient do
        line_number 14
        diff_refs { noteable.try(:diff_refs) }
      end

      position do
        Gitlab::Diff::Position.new(
          old_path: "files/ruby/popen.rb",
          new_path: "files/ruby/popen.rb",
          old_line: nil,
          new_line: line_number,
          diff_refs: diff_refs
        )
      end

      trait :resolved do
        resolved_at { Time.now }
        resolved_by { create(:user) }
      end
    end

    factory :diff_note_on_commit, traits: [:on_commit], class: DiffNote do
      association :project, :repository

      transient do
        line_number 14
        diff_refs { project.commit(commit_id).try(:diff_refs) }
      end

      position do
        Gitlab::Diff::Position.new(
          old_path: "files/ruby/popen.rb",
          new_path: "files/ruby/popen.rb",
          old_line: nil,
          new_line: line_number,
          diff_refs: diff_refs
        )
      end
    end

    trait :on_commit do
      association :project, :repository
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

    trait :on_snippet do
      noteable { create(:snippet, project: project) }
    end

    trait :on_merge_request do
      noteable { create(:merge_request, source_project: project) }
    end

    trait :on_project_snippet do
      noteable { create(:project_snippet, project: project) }
    end

    trait :on_personal_snippet do
      noteable { create(:personal_snippet) }
      project nil
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
      attachment { fixture_file_upload(Rails.root.join( "spec/fixtures/dk.png"), "image/png") }
    end

    trait :with_svg_attachment do
      attachment { fixture_file_upload(Rails.root.join("spec/fixtures/unsanitized.svg"), "image/svg+xml") }
    end

    transient do
      in_reply_to nil
    end

    before(:create) do |note, evaluator|
      discussion = evaluator.in_reply_to
      next unless discussion

      discussion = discussion.to_discussion if discussion.is_a?(Note)
      next unless discussion

      note.assign_attributes(discussion.reply_attributes.merge(project: discussion.project))
    end
  end
end
