FactoryGirl.define do
  factory :sent_notification do
    project
    recipient factory: :user
    noteable factory: :issue
    reply_key "0123456789abcdef" * 2
  end
end
