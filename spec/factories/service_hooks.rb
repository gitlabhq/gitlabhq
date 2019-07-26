# frozen_string_literal: true

FactoryBot.define do
  factory :service_hook do
    url { generate(:url) }
    service
  end
end
