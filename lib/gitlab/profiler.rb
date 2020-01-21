# frozen_string_literal: true

module Gitlab
  module Profiler
    FILTERED_STRING = '[FILTERED]'

    IGNORE_BACKTRACES = %w[
      lib/gitlab/i18n.rb
      lib/gitlab/request_context.rb
      config/initializers
      lib/gitlab/database/load_balancing/
      lib/gitlab/etag_caching/
      lib/gitlab/metrics/
      lib/gitlab/middleware/
      ee/lib/gitlab/middleware/
      lib/gitlab/performance_bar/
      lib/gitlab/request_profiler/
      lib/gitlab/query_limiting/
      lib/gitlab/tracing/
      lib/gitlab/profiler.rb
      lib/gitlab/correlation_id.rb
      lib/gitlab/webpack/dev_server_middleware.rb
      lib/gitlab/sidekiq_status/
      lib/gitlab/sidekiq_logging/
      lib/gitlab/sidekiq_middleware/
    ].freeze

    # Takes a URL to profile (can be a fully-qualified URL, or an absolute path)
    # and returns the ruby-prof profile result. Formatting that result is the
    # caller's responsibility. Requests are GET requests unless post_data is
    # passed.
    #
    # Optional arguments:
    # - logger: will be used for SQL logging, including a summary at the end of
    #   the log file of the total time spent per model class.
    #
    # - post_data: a string of raw POST data to use. Changes the HTTP verb to
    #   POST.
    #
    # - user: a user to authenticate as.
    #
    # - private_token: instead of providing a user instance, the token can be
    #   given as a string. Takes precedence over the user option.
    def self.profile(url, logger: nil, post_data: nil, user: nil, private_token: nil)
      app = ActionDispatch::Integration::Session.new(Rails.application)
      verb = :get
      headers = {}

      if post_data
        verb = :post
        headers['Content-Type'] = 'application/json'
      end

      if private_token
        headers['Private-Token'] = private_token
        user = nil # private_token overrides user
      end

      logger = create_custom_logger(logger, private_token: private_token)

      RequestStore.begin!

      # Make an initial call for an asset path in development mode to avoid
      # sprockets dominating the profiler output.
      ActionController::Base.helpers.asset_path('katex.css') if Rails.env.development?

      # Rails loads internationalization files lazily the first time a
      # translation is needed. Running this prevents this overhead from showing
      # up in profiles.
      ::I18n.t('.')[:test_string]

      # Remove API route mounting from the profile.
      app.get('/api/v4/users')

      result = with_custom_logger(logger) do
        with_user(user) do
          RubyProf.profile { app.public_send(verb, url, params: post_data, headers: headers) } # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      RequestStore.end!

      log_load_times_by_model(logger)

      result
    end

    def self.create_custom_logger(logger, private_token: nil)
      return unless logger

      logger.dup.tap do |new_logger|
        new_logger.instance_variable_set(:@private_token, private_token)

        class << new_logger
          attr_reader :load_times_by_model, :private_token

          def debug(message, *)
            message = message.gsub(private_token, FILTERED_STRING) if private_token

            _, type, time = *message.match(/(\w+) Load \(([0-9.]+)ms\)/)

            if type && time
              @load_times_by_model ||= {}
              @load_times_by_model[type] ||= []
              @load_times_by_model[type] << time.to_f
            end

            super

            Gitlab::BacktraceCleaner.clean_backtrace(caller).each do |caller_line|
              stripped_caller_line = caller_line.sub("#{Rails.root}/", '')

              super("  ↳ #{stripped_caller_line}")
            end
          end
        end
      end
    end

    def self.with_custom_logger(logger)
      original_colorize_logging = ActiveSupport::LogSubscriber.colorize_logging
      original_activerecord_logger = ActiveRecord::Base.logger
      original_actioncontroller_logger = ActionController::Base.logger

      if logger
        ActiveSupport::LogSubscriber.colorize_logging = false
        ActiveRecord::Base.logger = logger
        ActionController::Base.logger = logger
      end

      yield.tap do
        ActiveSupport::LogSubscriber.colorize_logging = original_colorize_logging
        ActiveRecord::Base.logger = original_activerecord_logger
        ActionController::Base.logger = original_actioncontroller_logger
      end
    end

    def self.with_user(user)
      if user
        API::Helpers::CommonHelpers.send(:define_method, :find_current_user!) { user } # rubocop:disable GitlabSecurity/PublicSend
        ApplicationController.send(:define_method, :current_user) { user } # rubocop:disable GitlabSecurity/PublicSend
        ApplicationController.send(:define_method, :authenticate_user!) { } # rubocop:disable GitlabSecurity/PublicSend
      end

      yield.tap do
        remove_method(API::Helpers::CommonHelpers, :find_current_user!)
        remove_method(ApplicationController, :current_user)
        remove_method(ApplicationController, :authenticate_user!)
      end
    end

    def self.remove_method(klass, meth)
      klass.send(:remove_method, meth) if klass.instance_methods(false).include?(meth) # rubocop:disable GitlabSecurity/PublicSend
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def self.log_load_times_by_model(logger)
      return unless logger.respond_to?(:load_times_by_model)

      summarised_load_times = logger.load_times_by_model.to_a.map do |(model, times)|
        [model, times.count, times.sum]
      end

      summarised_load_times.sort_by(&:last).reverse_each do |(model, query_count, time)|
        logger.info("#{model} total (#{query_count}): #{time.round(2)}ms")
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def self.print_by_total_time(result, options = {})
      default_options = { sort_method: :total_time }

      Gitlab::Profiler::TotalTimeFlatPrinter.new(result).print(STDOUT, default_options.merge(options))
    end
  end
end
