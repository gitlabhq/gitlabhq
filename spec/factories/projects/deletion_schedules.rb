# frozen_string_literal: true

FactoryBot.define do
  factory :project_deletion_schedule, class: 'Projects::DeletionSchedule' do
    association :project, factory: :project
    association :deleting_user, factory: :user
    marked_for_deletion_at { Time.current }
  end
end
