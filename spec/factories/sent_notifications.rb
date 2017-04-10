FactoryGirl.define do
  factory :sent_notification do
    project factory: :empty_project
    recipient factory: :user
    noteable { create(:issue, project: project) }
    reply_key { SentNotification.reply_key }
  end
end
