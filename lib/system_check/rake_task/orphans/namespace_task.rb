# frozen_string_literal: true

module SystemCheck
  module RakeTask
    module Orphans
      # Used by gitlab:orphans:check_namespaces rake task
      class NamespaceTask
        extend RakeTaskHelpers

        def self.name
          'Orphans'
        end

        def self.checks
          [SystemCheck::Orphans::NamespaceCheck]
        end
      end
    end
  end
end
