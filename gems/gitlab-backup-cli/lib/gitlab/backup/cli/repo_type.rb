# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      class RepoType
        PROJECT = :project
        WIKI    = :wiki
        SNIPPET = :snippet
        DESIGN  = :design
      end
    end
  end
end
