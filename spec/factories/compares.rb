# frozen_string_literal: true

FactoryBot.define do
  factory :compare do
    skip_create # No persistence

    start_project { association(:project, :repository) }
    target_project { start_project }

    start_ref { 'master' }
    target_ref { 'feature' }

    base_sha { nil }
    straight { false }

    initialize_with do
      CompareService
        .new(start_project, start_ref)
        .execute(target_project, target_ref, base_sha: base_sha, straight: straight)
    end
  end
end
