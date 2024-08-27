# frozen_string_literal: true

if Gem::Version.new(Sidekiq::VERSION) != Gem::Version.new('7.2.4')
  raise 'New version of sidekiq detected, please remove or update this patch'
end

module Gitlab
  module Patch
    module SidekiqJobSetter
      # Sidekiq::Job::Setter's .perform_in and .perform_async indirectly calls perform_async
      # so we only need to patch 1 method.
      def perform_async(*args)
        # rubocop:disable Gitlab/ModuleWithInstanceVariables -- @klass is present in the class we are patching

        route_with_klass = @klass

        # If an ActiveJob JobWrapper is pushed, check the arg hash's job_class for routing decisions.
        #
        # See https://github.com/rails/rails/blob/v7.1.0/activejob/lib/active_job/queue_adapters/sidekiq_adapter.rb#L21
        # `job.serialize` would return a hash containing `job_class` set in
        # https://github.com/rails/rails/blob/v7.1.0/activejob/lib/active_job/core.rb#L110
        #
        # In the GitLab Rails application, this only applies to ActionMailer::MailDeliveryJob
        # but routing using the `job_class` keeps the option of using ActiveJob available for us.
        #
        if @klass == ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper &&
            args.first.is_a?(Hash) &&
            args.first['job_class']
          route_with_klass = args.first['job_class'].to_s.safe_constantize
        end

        Gitlab::SidekiqSharding::Router.route(route_with_klass) do
          # rubocop:enable Gitlab/ModuleWithInstanceVariables
          super
        end
      end
    end
  end
end
