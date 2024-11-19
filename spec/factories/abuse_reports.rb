# frozen_string_literal: true

FactoryBot.define do
  factory :abuse_report do
    reporter factory: :user
    user
    message { 'User sends spam' }
    reported_from_url { 'http://gitlab.com' }
    links_to_spam { ['https://gitlab.com/issue1', 'https://gitlab.com/issue2'] }

    trait :closed do
      status { 'closed' }
      resolved_by factory: :user
    end

    trait :with_screenshot do
      screenshot { fixture_file_upload('spec/fixtures/dk.png') }
    end

    trait :with_assignee do
      assignees { [association(:assignee)] }
    end

    trait :with_evidence do
      evidence do
        {
          "user" => {
            "login_count" => rand(0..1000),
            "account_age" => rand(0..1000),
            "spam_score" => rand(0.0..1.0),
            "telesign_score" => rand(0.0..1.0),
            "arkos_score" => rand(0.0..1.0),
            "pvs_score" => rand(0.0..1.0),
            "product_coverage" => rand(0.0..1.0),
            "virus_total_score" => rand(0.0..1.0)
          }
        }
      end
    end

    trait :with_labels do
      labels { [association(:abuse_report_label)] }
    end
  end
end
