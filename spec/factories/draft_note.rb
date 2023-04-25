# frozen_string_literal: true
FactoryBot.define do
  factory :draft_note do
    note { generate(:title) }
    association :author, factory: :user
    association :merge_request, factory: :merge_request

    factory :draft_note_on_text_diff do
      transient do
        line_number { 14 }
        diff_refs { merge_request.try(:diff_refs) }
        path { "files/ruby/popen.rb" }
      end

      position do
        Gitlab::Diff::Position.new(
          old_path: path,
          new_path: path,
          old_line: nil,
          new_line: line_number,
          diff_refs: diff_refs
        )
      end

      factory :draft_note_on_image_diff do
        transient do
          path { "files/images/any_image.png" }
        end

        position do
          association(:image_diff_position, file: path, diff_refs: diff_refs)
        end
      end
    end

    factory :draft_note_on_discussion, traits: [:on_discussion]

    trait :on_discussion do
      discussion_id { association(:discussion_note_on_merge_request, noteable: merge_request, project: project).discussion_id }
    end
  end
end
