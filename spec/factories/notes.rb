# frozen_string_literal: true

require_relative '../support/helpers/repo_helpers'

FactoryBot.define do
  factory :note do
    project
    note { generate(:title) }
    author { project&.creator || association(:user) }
    on_issue

    factory :note_on_commit,             traits: [:on_commit]
    factory :note_on_issue,              traits: [:on_issue], aliases: [:votable_note]
    factory :note_on_merge_request,      traits: [:on_merge_request]
    factory :note_on_project_snippet,    traits: [:on_project_snippet]
    factory :note_on_personal_snippet,   traits: [:on_personal_snippet]
    factory :note_on_design,             traits: [:on_design]
    factory :note_on_alert,              traits: [:on_alert]
    factory :system_note,                traits: [:system]

    factory :discussion_note, class: 'DiscussionNote'

    factory :discussion_note_on_merge_request, traits: [:on_merge_request], class: 'DiscussionNote' do
      association :project, :repository
    end

    factory :track_mr_picking_note, traits: [:on_merge_request, :system] do
      association :system_note_metadata, action: 'cherry_pick'
      commit_id { RepoHelpers.sample_commit.id }
    end

    factory :discussion_note_on_issue, traits: [:on_issue], class: 'DiscussionNote'

    factory :discussion_note_on_commit, traits: [:on_commit], class: 'DiscussionNote'

    factory :discussion_note_on_personal_snippet, traits: [:on_personal_snippet], class: 'DiscussionNote'

    factory :discussion_note_on_project_snippet, traits: [:on_project_snippet], class: 'DiscussionNote'

    factory :legacy_diff_note_on_commit, traits: [:on_commit, :legacy_diff_note], class: 'LegacyDiffNote'

    factory :legacy_diff_note_on_merge_request, traits: [:on_merge_request, :legacy_diff_note], class: 'LegacyDiffNote' do
      association :project, :repository
      position { '' }
    end

    factory :diff_note_on_merge_request, traits: [:on_merge_request], class: 'DiffNote' do
      association :project, :repository

      transient do
        line_number { 14 }
        diff_refs { noteable.try(:diff_refs) }
      end

      position do
        association(:text_diff_position,
              file: "files/ruby/popen.rb",
              old_line: nil,
              new_line: line_number,
              diff_refs: diff_refs)
      end

      trait :folded_position do
        position do
          association(:text_diff_position,
                file: "files/ruby/popen.rb",
                old_line: 1,
                new_line: 1,
                diff_refs: diff_refs)
        end
      end

      factory :image_diff_note_on_merge_request do
        position do
          association(:image_diff_position,
                file: "files/images/any_image.png",
                diff_refs: diff_refs)
        end
      end
    end

    factory :diff_note_on_commit, traits: [:on_commit], class: 'DiffNote' do
      association :project, :repository

      transient do
        line_number { 14 }
        diff_refs { project.commit(commit_id).try(:diff_refs) }
      end

      position do
        association(:text_diff_position,
          file: "files/ruby/popen.rb",
          old_line: nil,
          new_line: line_number,
          diff_refs: diff_refs
        )
      end
    end

    factory :diff_note_on_design, parent: :note, traits: [:on_design], class: 'DiffNote' do
      position do
        association(:image_diff_position,
              file: noteable.full_path,
              diff_refs: noteable.diff_refs)
      end
    end

    trait :on_commit do
      association :project, :repository
      noteable { nil }
      noteable_type { 'Commit' }
      noteable_id { nil }
      commit_id { RepoHelpers.sample_commit.id }
    end

    trait :legacy_diff_note do
      line_code { "0_184_184" }
    end

    trait :on_issue do
      noteable { association(:issue, project: project) }
    end

    trait :on_merge_request do
      noteable { association(:merge_request, source_project: project) }
    end

    trait :on_project_snippet do
      noteable { association(:project_snippet, project: project) }
    end

    trait :on_personal_snippet do
      noteable { association(:personal_snippet) }
      project { nil }
    end

    trait :on_design do
      transient do
        issue { association(:issue, project: project) }
      end
      noteable { association(:design, :with_file, issue: issue) }

      after(:build) do |note|
        next if note.project == note.noteable.project

        # note validations require consistency between these two objects
        note.project = note.noteable.project
      end
    end

    trait :on_alert do
      noteable { association(:alert_management_alert, project: project) }
    end

    trait :resolved do
      resolved_at { Time.now }
      resolved_by { association(:user) }
    end

    trait :system do
      system { true }
    end

    trait :with_system_note_metadata do
      system
      system_note_metadata
    end

    trait :downvote do
      note { "thumbsdown" }
    end

    trait :upvote do
      note { "thumbsup" }
    end

    trait :with_attachment do
      attachment { fixture_file_upload("spec/fixtures/dk.png", "image/png") }
    end

    trait :with_svg_attachment do
      attachment { fixture_file_upload("spec/fixtures/unsanitized.svg", "image/svg+xml") }
    end

    trait :with_pdf_attachment do
      attachment { fixture_file_upload("spec/fixtures/git-cheat-sheet.pdf", "application/pdf") }
    end

    trait :confidential do
      confidential { true }
    end

    trait :with_review do
      review
    end

    transient do
      in_reply_to { nil }
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
