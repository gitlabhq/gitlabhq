# frozen_string_literal: true

require_relative "subcommands/deployment"

module Gitlab
  module Cng
    module Commands
      # Create command composed of subcommands that create various resources needed for CNG deployment
      #
      class Create < Command
        # TODO: without separate cluster creation command, create subcommands are somewhat redundant,
        # consider removing
        desc "deployment [TYPE]", "Create specific type of deployment"
        subcommand "deployment", Subcommands::Deployment
      end
    end
  end
end
