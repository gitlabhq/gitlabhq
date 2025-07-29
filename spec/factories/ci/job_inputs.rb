# frozen_string_literal: true

FactoryBot.define do
  factory :ci_job_input, class: 'Ci::JobInput' do
    sequence(:name) { |n| "input_#{n}" }

    sensitive { false }
    input_type { 'string' }
    value { 'value' }

    job factory: :ci_build
  end
end
