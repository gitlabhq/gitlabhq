# frozen_string_literal: true

module SystemCheck
  module RakeTask
    # Used by gitlab:incoming_email:check rake task
    class IncomingEmailTask
      extend RakeTaskHelpers

      def self.name
        'Incoming Email'
      end

      def self.checks
        [SystemCheck::IncomingEmailCheck]
      end
    end
  end
end
