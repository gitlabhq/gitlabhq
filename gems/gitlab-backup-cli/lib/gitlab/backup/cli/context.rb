# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Context
        autoload :SourceContext, 'gitlab/backup/cli/context/source_context'
        autoload :OmnibusContext, 'gitlab/backup/cli/context/omnibus_context'
        autoload :OmnibusConfig, 'gitlab/backup/cli/context/omnibus_config'

        def self.build
          if ::Gitlab::Backup::Cli::Context::OmnibusContext.available?
            ::Gitlab::Backup::Cli::Context::OmnibusContext.new
          else
            ::Gitlab::Backup::Cli::Context::SourceContext.new
          end
        end
      end
    end
  end
end
