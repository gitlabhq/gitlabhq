# frozen_string_literal: true

module Ci
  class GenerateKubeconfigService
    def initialize(build)
      @build = build
      @template = Gitlab::Kubernetes::Kubeconfig::Template.new
    end

    def execute
      template.add_cluster(
        name: cluster_name,
        url: Gitlab::Kas.tunnel_url
      )

      agents.each do |agent|
        user = user_name(agent)

        template.add_user(
          name: user,
          token: agent_token(agent)
        )

        template.add_context(
          name: context_name(agent),
          cluster: cluster_name,
          user: user
        )
      end

      template
    end

    private

    attr_reader :build, :template

    def agents
      build.pipeline.authorized_cluster_agents
    end

    def cluster_name
      'gitlab'
    end

    def user_name(agent)
      ['agent', agent.id].join(delimiter)
    end

    def context_name(agent)
      [agent.project.full_path, agent.name].join(delimiter)
    end

    def agent_token(agent)
      ['ci', agent.id, build.token].join(delimiter)
    end

    def delimiter
      ':'
    end
  end
end
