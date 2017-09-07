module Gitlab
  class ApiLogger < ::Logger
    def format_message(severity, timestamp, progname, message)
      super + "\n"
    end
  end
end
