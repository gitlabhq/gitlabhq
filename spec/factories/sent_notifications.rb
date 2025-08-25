# frozen_string_literal: true

FactoryBot.define do
  factory :sent_notification do
    project
    recipient { project.creator }
    noteable { association(:issue, project: project) }
    reply_key { SentNotification.reply_key }

    trait :legacy_reply_key do
      reply_key { SecureRandom.hex(16) }
    end
  end
end
