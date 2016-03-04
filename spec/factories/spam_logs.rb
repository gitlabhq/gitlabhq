FactoryGirl.define do
  factory :spam_log do
    user
    source_ip { FFaker::Internet.ip_v4_address }
    noteable_type 'Issue'
    title { FFaker::Lorem.sentence }
    description { FFaker::Lorem.paragraph(5) }
  end
end
