# frozen_string_literal: true

module Gitlab
  module Cng
    module Commands
      # Create command composed of subcommands that create various resources needed for CNG deployment
      #
      class Create < Command
        desc "cluster", "Create kind cluster for local deployments"
        option :name,
          desc: "Cluster name",
          default: "gitlab",
          type: :string,
          aliases: "-n"
        option :ci,
          desc: "Use CI specific configuration",
          default: false,
          type: :boolean,
          aliases: "-c"
        option :docker_hostname,
          desc: "Custom docker hostname if remote docker instance is used, like docker-in-docker",
          type: :string,
          aliases: "-d"
        def cluster
          Kind::Cluster.new(**symbolized_options).create
        end
      end
    end
  end
end
