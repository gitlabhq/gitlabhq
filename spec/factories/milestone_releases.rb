# frozen_string_literal: true

FactoryBot.define do
  factory :milestone_release do
    transient do
      project { association(:project) }
    end

    milestone { association(:milestone, project: project) }
    release { association(:release, project: project) }
  end
end
