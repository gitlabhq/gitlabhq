FactoryGirl.define do
  factory :award_emoji do
    name "thumbsup"
    user
    awardable factory: :issue
  end
end
