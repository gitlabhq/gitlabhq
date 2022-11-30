# frozen_string_literal: true

FactoryBot.define do
  factory :project_ci_feature_usage, class: 'Projects::CiFeatureUsage' do
    project factory: :project
    feature { :code_coverage } # rubocop: disable RSpec/EmptyExampleGroup

    default_branch { false }
  end
end
