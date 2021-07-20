# frozen_string_literal: true

FactoryBot.define do
  factory :ci_pending_build, class: 'Ci::PendingBuild' do
    build factory: :ci_build
    project
    protected { build.protected }
    instance_runners_enabled { true }
  end
end
