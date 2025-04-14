# frozen_string_literal: true

require_relative "subcommands/deployment"
require_relative "subcommands/instance"

module Gitlab
  module Orchestrator
    module Commands
      # Create command composed of subcommands that create various resources needed for CNG deployment
      #
      class Create < Command
        # Creates a deployment of GitLab on a Kubernetes cluster
        # The [TYPE] parameter specifies the deployment type (e.g., 'kind' for a local Kubernetes cluster)
        # Example: orchestrator create deployment kind
        desc "deployment [TYPE]", "Create specific type of deployment"
        subcommand "deployment", Subcommands::Deployment

        # Creates a GitLab instance running in a container
        # The [TYPE] parameter specifies the instance type (e.g., 'gitlab' for a Docker-based GitLab instance)
        # Example: orchestrator create instance gitlab
        desc "instance [TYPE]", "Create specific type of instance"
        subcommand "instance", Subcommands::Instance
      end
    end
  end
end
