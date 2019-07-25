# frozen_string_literal: true

FactoryBot.define do
  factory :system_hook do
    url { generate(:url) }
  end
end
