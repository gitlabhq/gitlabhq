# frozen_string_literal: true

FactoryBot.define do
  factory :import_placeholder_membership, class: 'Import::Placeholders::Membership' do
    source_user factory: :import_source_user
    namespace { source_user.namespace }
    project
    access_level { Gitlab::Access::GUEST }

    trait :for_group do
      project { nil }
      group
    end
  end
end
