# frozen_string_literal: true

FactoryBot.define do
  factory :ci_build_metadata, class: 'Ci::BuildMetadata' do
    config_options { { script: ['script-record'], services: ['services-record'] } }
    build { association(:ci_build, strategy: :build, metadata: instance) }
  end
end
