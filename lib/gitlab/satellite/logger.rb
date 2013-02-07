module Gitlab
  module Satellite
    class Logger < Gitlab::Logger
      def self.file_name
        'satellites.log'
      end

      def format_message(severity, timestamp, progname, msg)
        "#{timestamp.to_s(:long)}: #{msg}\n"
      end
    end
  end
end
