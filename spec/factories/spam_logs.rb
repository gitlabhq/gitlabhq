FactoryBot.define do
  factory :spam_log do
    user
    sequence(:source_ip) { |n| "42.42.42.#{n % 255}" }
    noteable_type 'Issue'
    sequence(:title) { |n| "Spam title #{n}" }
    description { "Spam description\nwith\nmultiple\nlines" }
  end
end
