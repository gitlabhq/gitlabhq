# frozen_string_literal: true

class QueryRecorder
  attr_reader :log

  def initialize(&block)
    @log = []

    ActiveRecord::Base.connection.unprepared_statement do
      ActiveSupport::Notifications.subscribed(method(:callback), 'sql.active_record', &block)
    end
  end

  def callback(_name, _start, _finish, _message_id, values)
    @log << values[:sql]
  end

  def self.log(&block)
    new(&block).log
  end
end
