# frozen_string_literal: true

FactoryBot.define do
  factory :catalog_verified_namespace, class: 'Ci::Catalog::VerifiedNamespace' do
    namespace factory: :namespace

    trait :gitlab_maintained do
      verification_level { :gitlab_maintained }
    end

    trait :partner do
      verification_level { :partner }
    end

    trait :verified_creator do
      verification_level { :verified_creator }
    end
  end
end
