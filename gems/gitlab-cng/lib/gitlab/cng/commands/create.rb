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

        desc "deployment [NAME]", "Create CNG deployment from official GitLab Helm chart"
        long_desc <<~LONGDESC
          This command installs a GitLab chart archive and performs all additional pre-install and post-install setup.
          Argument NAME is helm install name and defaults to "gitlab".
        LONGDESC
        option :configuration,
          desc: "Deployment configuration",
          default: "kind",
          type: :string,
          aliases: "-c",
          enum: ["kind"]
        option :namespace,
          desc: "Deployment namespace",
          default: "gitlab",
          type: :string,
          aliases: "-n"
        option :set,
          desc: "Optional helm chart values (can specify multiple or separate values with commas: key1=val1,key2=val2)",
          type: :string,
          repeatable: true
        option :ci,
          desc: "Use CI specific configuration",
          default: false,
          type: :boolean
        def deployment(name = "gitlab")
          Deployment::Installation.new(name, **symbolized_options).create
        end
      end
    end
  end
end
