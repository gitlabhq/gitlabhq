# frozen_string_literal: true

module Gitlab
  module Cng
    module Commands
      # Basic command to print the version of cng orchestrator
      #
      class Version < Command
        desc "version", "Print cng orchestrator version"
        def version
          puts Cng::VERSION
        end
      end
    end
  end
end
