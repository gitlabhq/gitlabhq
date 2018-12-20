# frozen_string_literal: true

module SystemCheck
  module RakeTask
    # Used by gitlab:sidekiq:check rake task
    class SidekiqTask
      extend RakeTaskHelpers

      def self.name
        'Sidekiq'
      end

      def self.checks
        [SystemCheck::SidekiqCheck]
      end
    end
  end
end
