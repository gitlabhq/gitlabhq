module MailSchedulerQueue
  extend ActiveSupport::Concern

  included do
    queue_namespace :mail_scheduler
  end
end
