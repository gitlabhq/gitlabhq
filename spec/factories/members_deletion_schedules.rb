# frozen_string_literal: true

FactoryBot.define do
  factory :members_deletion_schedules, class: 'Members::DeletionSchedule' do
    namespace { association(:group) }
    user { association(:user) }
    scheduled_by { association(:user) }
  end
end
