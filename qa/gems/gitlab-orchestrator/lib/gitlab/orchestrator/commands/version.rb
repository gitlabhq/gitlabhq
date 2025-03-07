# frozen_string_literal: true

module Gitlab
  module Orchestrator
    module Commands
      # Basic command to print the version of orchestrator
      #
      class Version < Command
        desc "version", "Print orchestrator version"
        def version
          puts Orchestrator::VERSION
        end
      end
    end
  end
end
