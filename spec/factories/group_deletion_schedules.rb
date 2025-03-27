# frozen_string_literal: true

FactoryBot.define do
  factory :group_deletion_schedule do
    association :group, factory: :group
    association :deleting_user, factory: :user
    marked_for_deletion_on { Date.current }
  end
end
