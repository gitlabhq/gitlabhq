# frozen_string_literal: true

FactoryBot.define do
  factory :catalog_verified_namespace, class: 'Ci::Catalog::VerifiedNamespace' do
    namespace factory: :namespace

    trait :gitlab_maintained do
      verification_level { :gitlab_maintained }
    end

    trait :gitlab_partner_maintained do
      verification_level { :gitlab_partner_maintained }
    end

    trait :verified_creator_maintained do
      verification_level { :verified_creator_maintained }
    end
  end
end
