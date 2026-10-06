# frozen_string_literal: true

FactoryBot.define do
  factory :project_ci_feature_usage, class: 'Projects::CiFeatureUsage' do
    project factory: :project
    add_attribute(:feature) { :code_coverage }

    default_branch { false }
  end
end
