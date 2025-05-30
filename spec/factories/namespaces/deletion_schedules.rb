# frozen_string_literal: true

FactoryBot.define do
  factory :namespace_deletion_schedule, class: 'Namespaces::DeletionSchedule' do
    association :namespace, factory: :namespace
    association :deleting_user, factory: :user
    marked_for_deletion_at { Time.current }
  end
end
