FactoryBot.define do
  factory :sent_notification do
    project
    recipient factory: :user
    noteable { create(:issue, project: project) }
    reply_key { SentNotification.reply_key }
  end
end
