# frozen_string_literal: true

FactoryBot.define do
  factory :in_product_marketing_email, class: 'Users::InProductMarketingEmail' do
    user

    track { 'create' }
    series { 0 }
  end
end
