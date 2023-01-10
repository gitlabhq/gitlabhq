# frozen_string_literal: true

FactoryBot.define do
  factory :project_build_artifacts_size_refresh, class: 'Projects::BuildArtifactsSizeRefresh' do
    project factory: :project

    trait :created do
      state { Projects::BuildArtifactsSizeRefresh::STATES[:created] }
    end

    trait :pending do
      state { Projects::BuildArtifactsSizeRefresh::STATES[:pending] }
      refresh_started_at { Time.zone.now }
    end

    trait :running do
      state { Projects::BuildArtifactsSizeRefresh::STATES[:running] }
      refresh_started_at { Time.zone.now }
    end

    trait :finalizing do
      state { Projects::BuildArtifactsSizeRefresh::STATES[:finalizing] }
    end

    trait :stale do
      running
      refresh_started_at { 30.days.ago }
      updated_at { 30.days.ago }
    end
  end
end
