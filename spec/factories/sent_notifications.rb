# frozen_string_literal: true

FactoryBot.define do
  factory :sent_notification do
    project
    recipient { project.creator }
    noteable { association(:issue, project: project) }
    reply_key { SentNotification.reply_key }
  end
end
