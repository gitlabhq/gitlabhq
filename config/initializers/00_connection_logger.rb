# frozen_string_literal: true

module NewConnectionLogger
  extend ActiveSupport::Concern

  prepended do |base|
    base.class_attribute :warn_on_new_connection, default: false
  end

  class_methods do
    def new_client(...)
      if warn_on_new_connection && !ENV['SKIP_LOG_INITIALIZER_CONNECTIONS']
        cleaned_caller = Gitlab::BacktraceCleaner.clean_backtrace(caller)
        message = "Database connection should not be called during initializers. Read more at https://docs.gitlab.com/ee/development/rails_initializers.html#database-connections-in-initializers"

        ActiveSupport::Deprecation.warn(message, cleaned_caller)

        warn caller if ENV['DEBUG_INITIALIZER_CONNECTIONS']
      end

      super
    end
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(NewConnectionLogger)
