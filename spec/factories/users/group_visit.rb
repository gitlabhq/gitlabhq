# frozen_string_literal: true

FactoryBot.define do
  factory :group_visit, class: 'Users::GroupVisit' do
    transient { target_user { association(:user) } }
    transient { target_group { association(:group) } }

    user_id { target_user.id }
    entity_id { target_group.id }
    visited_at { Time.now }
  end
end
