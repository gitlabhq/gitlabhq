# frozen_string_literal: true

FactoryBot.define do
  factory :project_visit, class: 'Users::ProjectVisit' do
    transient { target_user { association(:user) } }
    transient { target_project { association(:project) } }

    user_id { target_user.id }
    entity_id { target_project.id }
    visited_at { Time.now }
  end
end
