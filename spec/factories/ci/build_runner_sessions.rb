# frozen_string_literal: true

FactoryBot.define do
  factory :ci_build_runner_session, class: 'Ci::BuildRunnerSession' do
    build factory: :ci_build
    url { 'https://gitlab.example.com' }
  end
end
