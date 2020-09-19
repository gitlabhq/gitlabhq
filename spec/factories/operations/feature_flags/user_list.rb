# frozen_string_literal: true

FactoryBot.define do
  factory :operations_feature_flag_user_list, class: 'Operations::FeatureFlags::UserList' do
    association :project, factory: :project
    name { 'My User List' }
    user_xids { 'user1,user2,user3' }
  end
end
