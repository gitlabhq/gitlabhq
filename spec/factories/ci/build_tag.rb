# frozen_string_literal: true

FactoryBot.define do
  factory :ci_build_tag, class: 'Ci::BuildTag' do
    build factory: :ci_build
    tag factory: :ci_tag
    project_id { build.project_id }
  end
end
