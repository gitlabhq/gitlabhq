# frozen_string_literal: true

module SystemCheck
  module RakeTask
    # Used by gitlab:gitaly:check rake task
    class GitalyTask
      extend RakeTaskHelpers

      def self.name
        'Gitaly'
      end

      def self.checks
        [SystemCheck::GitalyCheck]
      end
    end
  end
end
