# frozen_string_literal: true

module Ci
  class GenerateKubeconfigService
    def initialize(pipeline, token:, environment:)
      @pipeline = pipeline
      @token = token
      @environment = environment

      @template = Gitlab::Kubernetes::Kubeconfig::Template.new
    end

    def execute
      template.add_cluster(
        name: cluster_name,
        url: Gitlab::Kas.tunnel_url
      )

      agent_authorizations.each do |authorization|
        agent = authorization.agent
        user = user_name(agent)

        template.add_user(
          name: user,
          token: agent_token(agent)
        )

        template.add_context(
          name: context_name(agent),
          namespace: context_namespace(authorization),
          cluster: cluster_name,
          user: user
        )
      end

      template
    end

    private

    attr_reader :pipeline, :token, :environment, :template

    def agent_authorizations
      ::Clusters::Agents::Authorizations::CiAccess::FilterService.new(
        pipeline.cluster_agent_authorizations,
        { environment: environment,
          protected_ref: pipeline.protected_ref? },
        pipeline.project
      ).execute
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

    def context_namespace(authorization)
      authorization.config['default_namespace']
    end

    def agent_token(agent)
      ['ci', agent.id, token].join(delimiter)
    end

    def delimiter
      ':'
    end
  end
end
