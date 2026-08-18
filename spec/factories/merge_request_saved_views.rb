# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_saved_view, class: 'MergeRequests::SavedView' do
    user
    sequence(:name) { |n| "Saved view #{n}" }

    trait :with_filters do
      filters do
        {
          'state' => 'opened',
          'assignee_usernames' => ['root'],
          'label_name' => %w[bug],
          'not' => { 'author_username' => 'someone-else' }
        }
      end
    end
  end
end
