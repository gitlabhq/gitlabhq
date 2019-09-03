# frozen_string_literal: true

FactoryBot.define do
  factory :milestone_release do
    milestone
    release

    before(:create, :build) do |mr|
      project = create(:project)
      mr.milestone.project = project
      mr.release.project = project
    end
  end
end
