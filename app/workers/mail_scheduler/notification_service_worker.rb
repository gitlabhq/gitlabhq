# frozen_string_literal: true

require 'active_job/arguments'

module MailScheduler
  class NotificationServiceWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include MailSchedulerQueue

    feature_category :issue_tracking
    worker_resource_boundary :cpu
    loggable_arguments 0

    def perform(meth, *args)
      check_arguments!(args)

      deserialized_args = ActiveJob::Arguments.deserialize(args)
      notification_service.public_send(meth, *deserialized_args) # rubocop:disable GitlabSecurity/PublicSend
    rescue ActiveJob::DeserializationError
      # No-op.
      # This exception gets raised when an argument
      # is correct (deserializeable), but it still cannot be deserialized.
      # This can happen when an object has been deleted after
      # rails passes this job to sidekiq, but before
      # sidekiq gets it for execution.
      # In this case just do nothing.
    end

    def self.perform_async(*args)
      super(*ActiveJob::Arguments.serialize(args))
    end

    private

    # This is copied over from https://github.com/rails/rails/blob/v6.0.1/activejob/lib/active_job/arguments.rb#L50
    # because it is declared as a private constant
    PERMITTED_TYPES = [NilClass, String, Integer, Float, BigDecimal, TrueClass, FalseClass].freeze

    private_constant :PERMITTED_TYPES

    # If an argument is in the PERMITTED_TYPES list,
    # it means the argument cannot be deserialized.
    # Which means there's something wrong with our code.
    def check_arguments!(args)
      args.each do |arg|
        if arg.class.in?(PERMITTED_TYPES)
          raise(ArgumentError, "Argument `#{arg}` cannot be deserialized because of its type")
        end
      end
    end
  end
end
