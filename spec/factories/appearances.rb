# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :appearance do
    title "GitLab Community Edition"
    description "Open source software to collaborate on code"
    new_project_guidelines "Custom project guidelines"
  end

  trait :with_logo do
    logo { fixture_file_upload('spec/fixtures/dk.png') }
  end

  trait :with_header_logo do
    header_logo { fixture_file_upload('spec/fixtures/dk.png') }
  end

  trait :with_favicon do
    favicon { fixture_file_upload('spec/fixtures/dk.png') }
  end

  trait :with_logos do
    with_logo
    with_header_logo
  end
end
