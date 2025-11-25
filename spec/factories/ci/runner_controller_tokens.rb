# frozen_string_literal: true

FactoryBot.define do
  factory :ci_runner_controller_token, class: 'Ci::RunnerControllerToken' do
    association :runner_controller, factory: :ci_runner_controller

    description { "Token for runner controller" }
    token_digest { Digest::SHA256.hexdigest(SecureRandom.hex(32)) }
  end
end
