# frozen_string_literal: true

module Gitlab
  module Housekeeper
    class Logger < ::Logger
      def initialize(...)
        super

        self.formatter = Formatter.new
      end

      def puts(*args)
        args = [nil] if args.empty?
        args.each { |arg| self << "#{arg}\n" }
      end

      class Formatter < ::Logger::Formatter
        def call(severity, _time, _progname, msg)
          format("%s: %s\n", severity, msg2str(msg))
        end
      end
    end
  end
end
