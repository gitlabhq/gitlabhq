# frozen_string_literal: true

FactoryBot.define do
  factory :ci_job_definition, class: 'Ci::JobDefinition' do
    project factory: :project

    checksum { Digest::SHA256.hexdigest(rand.to_s) }
    interruptible { false }
  end
end
