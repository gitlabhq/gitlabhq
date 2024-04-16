# frozen_string_literal: true

Rails.application.config.after_initialize do
  ActionMailer::MailDeliveryJob.sidekiq_options retry: 3
  ActionMailer::MailDeliveryJob.include(WorkerAttributes)
  ActionMailer::MailDeliveryJob.data_consistency :delayed

  # ActionMailer::MailDeliveryJob is made compatible with the WorkerRouter using the DummyWorker class
  klass = Gitlab::SidekiqConfig::DEFAULT_WORKERS['ActionMailer::MailDeliveryJob'].klass

  # Assigns store once during initialisation instead of during active job enqueue
  store_name = Gitlab::SidekiqConfig::WorkerRouter.global.store(klass)
  ActionMailer::MailDeliveryJob.sidekiq_options store: store_name

  # Assigns store for JobWrapper class for accuracy of client-side metric's store label
  ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper.sidekiq_options store: store_name
end
