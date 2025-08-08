# frozen_string_literal: true

FactoryBot.define do
  factory :import_placeholder_user_details, class: 'Import::PlaceholderUserDetail' do
    placeholder_user factory: [:user, :placeholder]
    deletion_attempts { 0 }
    last_deletion_attempt_at { nil }
    namespace factory: :group
    organization { namespace&.organization || association(:common_organization) }

    trait :eligible_for_deletion do
      namespace { nil }
      deletion_attempts { 2 }
      last_deletion_attempt_at { 3.days.ago }
    end
  end
end
