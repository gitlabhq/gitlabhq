# frozen_string_literal: true

FactoryBot.define do
  factory :abuse_report_note, class: 'AntiAbuse::Reports::Note' do
    abuse_report { association(:abuse_report) }
    note { generate(:title) }
    author { association(:user) }
    updated_by { author }

    factory :abuse_report_discussion_note, class: 'AntiAbuse::Reports::DiscussionNote'

    transient do
      in_reply_to { nil }
    end

    before(:create) do |note, evaluator|
      discussion = evaluator.in_reply_to
      next unless discussion

      discussion = discussion.to_discussion if discussion.is_a?(AntiAbuse::Reports::Note)
      next unless discussion

      note.assign_attributes(discussion.reply_attributes)
    end
  end
end
