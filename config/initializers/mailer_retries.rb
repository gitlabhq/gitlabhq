# frozen_string_literal: true

Rails.application.config.after_initialize do
  ActionMailer::MailDeliveryJob.sidekiq_options retry: 3
  ActionMailer::MailDeliveryJob.include(WorkerAttributes)
  ActionMailer::MailDeliveryJob.data_consistency :delayed, feature_flag: :use_replica_for_mailers
end
