module Gitlab
  class DowntimeCheck
    class Message
      attr_reader :path, :offline, :reason

      OFFLINE = "\e[32moffline\e[0m"
      ONLINE = "\e[31monline\e[0m"

      # path - The file path of the migration.
      # offline - When set to `true` the migration will require downtime.
      # reason - The reason as to why the migration requires downtime.
      def initialize(path, offline = false, reason = nil)
        @path = path
        @offline = offline
        @reason = reason
      end

      def to_s
        label = offline ? OFFLINE : ONLINE

        message = "[#{label}]: #{path}"
        message += ": #{reason}" if reason

        message
      end
    end
  end
end
