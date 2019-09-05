# frozen_string_literal: true

module Gitlab
  class DowntimeCheck
    class Message
      attr_reader :path, :offline

      OFFLINE = "\e[31moffline\e[0m"
      ONLINE = "\e[32monline\e[0m"

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

        message = ["[#{label}]: #{path}"]

        if reason?
          message << ":\n\n#{reason}\n\n"
        end

        message.join
      end

      def reason?
        @reason.present?
      end

      def reason
        @reason.strip.lines.map(&:strip).join("\n")
      end
    end
  end
end
