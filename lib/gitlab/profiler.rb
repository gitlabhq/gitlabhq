# coding: utf-8
module Gitlab
  module Profiler
    FILTERED_STRING = '[FILTERED]'.freeze

    IGNORE_BACKTRACES = %w[
      lib/gitlab/i18n.rb
      lib/gitlab/request_context.rb
      config/initializers
      lib/gitlab/database/load_balancing/
      lib/gitlab/etag_caching/
      lib/gitlab/metrics/
      lib/gitlab/middleware/
      lib/gitlab/performance_bar/
      lib/gitlab/request_profiler/
      lib/gitlab/profiler.rb
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
    # - user: a user to authenticate as. Only works if the user has a valid
    #   personal access token.
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

      if user
        private_token ||= user.personal_access_tokens.active.pluck(:token).first
        raise 'Your user must have a personal_access_token' unless private_token
      end

      headers['Private-Token'] = private_token if private_token
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
        RubyProf.profile { app.public_send(verb, url, post_data, headers) } # rubocop:disable GitlabSecurity/PublicSend
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
            message.gsub!(private_token, FILTERED_STRING) if private_token

            _, type, time = *message.match(/(\w+) Load \(([0-9.]+)ms\)/)

            if type && time
              @load_times_by_model ||= {}
              @load_times_by_model[type] ||= []
              @load_times_by_model[type] << time.to_f
            end

            super

            backtrace = Rails.backtrace_cleaner.clean(caller)

            backtrace.each do |caller_line|
              next if caller_line.match(Regexp.union(IGNORE_BACKTRACES))

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

      result = yield

      ActiveSupport::LogSubscriber.colorize_logging = original_colorize_logging
      ActiveRecord::Base.logger = original_activerecord_logger
      ActionController::Base.logger = original_actioncontroller_logger

      result
    end

    def self.log_load_times_by_model(logger)
      return unless logger.respond_to?(:load_times_by_model)

      summarised_load_times = logger.load_times_by_model.to_a.map do |(model, times)|
        [model, times.count, times.sum]
      end

      summarised_load_times.sort_by(&:last).reverse.each do |(model, query_count, time)|
        logger.info("#{model} total (#{query_count}): #{time.round(2)}ms")
      end
    end
  end
end
