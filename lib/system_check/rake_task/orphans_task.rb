# frozen_string_literal: true

module SystemCheck
  module RakeTask
    # Used by gitlab:orphans:check rake task
    class OrphansTask
      extend RakeTaskHelpers

      def self.name
        'Orphans'
      end

      def self.checks
        [
          SystemCheck::Orphans::NamespaceCheck,
          SystemCheck::Orphans::RepositoryCheck
        ]
      end
    end
  end
end
