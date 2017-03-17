FactoryGirl.define do
  factory :sent_notification do
    project factory: :empty_project
    recipient factory: :user
    noteable factory: :issue
    reply_key { SentNotification.reply_key }
  end
end
