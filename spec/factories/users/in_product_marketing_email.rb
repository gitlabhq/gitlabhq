# frozen_string_literal: true

FactoryBot.define do
  factory :in_product_marketing_email, class: 'Users::InProductMarketingEmail' do
    user

    track { 'create' }
    series { 0 }

    trait :campaign do
      track { nil }
      series { nil }
      campaign { Users::InProductMarketingEmail::BUILD_IOS_APP_GUIDE }
    end
  end
end
