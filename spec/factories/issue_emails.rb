# frozen_string_literal: true

FactoryBot.define do
  factory :issue_email, class: 'Issue::Email' do
    issue
    email_message_id { generate(:short_text) }
  end
end
