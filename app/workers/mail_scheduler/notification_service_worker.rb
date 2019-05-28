# frozen_string_literal: true

require 'active_job/arguments'

module MailScheduler
  class NotificationServiceWorker
    include ApplicationWorker
    include MailSchedulerQueue

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
      super(*Arguments.serialize(args))
    end

    private

    # If an argument is in the ActiveJob::Arguments::TYPE_WHITELIST list,
    # it means the argument cannot be deserialized.
    # Which means there's something wrong with our code.
    def check_arguments!(args)
      args.each do |arg|
        if arg.class.in?(ActiveJob::Arguments::TYPE_WHITELIST)
          raise(ArgumentError, "Argument `#{arg}` cannot be deserialized because of its type")
        end
      end
    end

    # Permit ActionController::Parameters for serializable Hash
    #
    # Port of
    # https://github.com/rails/rails/commit/945fdd76925c9f615bf016717c4c8db2b2955357#diff-fc90ec41ef75be8b2259526fe1a8b663
    module Arguments
      include ActiveJob::Arguments
      extend self

      private

      def serialize_argument(argument)
        case argument
        when -> (arg) { arg.respond_to?(:permitted?) }
          serialize_hash(argument.to_h).tap do |result|
            result[WITH_INDIFFERENT_ACCESS_KEY] = serialize_argument(true)
          end
        else
          super
        end
      end
    end

    # Make sure we remove this patch starting with Rails 6.0.
    if Rails.version.start_with?('6.0')
      raise <<~MSG
        Please remove the patch `Arguments` module and use `ActiveJob::Arguments` again.
      MSG
    end
  end
end
