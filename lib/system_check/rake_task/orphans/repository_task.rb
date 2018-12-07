# frozen_string_literal: true

module SystemCheck
  module RakeTask
    module Orphans
      # Used by gitlab:orphans:check_repositories rake task
      class RepositoryTask
        extend RakeTaskHelpers

        def self.name
          'Orphans'
        end

        def self.checks
          [SystemCheck::Orphans::RepositoryCheck]
        end
      end
    end
  end
end
