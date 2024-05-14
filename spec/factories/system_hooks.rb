# frozen_string_literal: true

FactoryBot.define do
  factory :system_hook do
    url { generate(:url) }
    name { generate(:name) }
    description { "Description of #{name}" }
  end
end
