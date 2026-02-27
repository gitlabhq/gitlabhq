# frozen_string_literal: true

module InitializerConnections
  # Warns about any SQL queries made within the block by printing them to STDOUT.
  #
  # Routes and initializers should not issue database calls,
  # See also https://github.com/rails/rails/issues/44875
  #
  def self.warn_if_database_connection
    callback = ->(_name, _started, _finished, _unique_id, payload) do
      backtrace = Gitlab::BacktraceCleaner.clean_backtrace(caller).map do |line|
        "InitializerConnections Backtrace: #{line}"
      end

      warn(["InitializerConnections Query: #{payload[:sql]}", *backtrace].join("\n"))
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      yield
    end
  end
end
