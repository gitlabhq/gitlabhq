# frozen_string_literal: true

FactoryBot.define do
  factory :ci_runner_tagging, class: 'Ci::RunnerTagging' do
    runner factory: :ci_runner
    tag factory: :ci_tag

    organization_id { runner.organization_id }
  end
end
