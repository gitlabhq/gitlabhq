# frozen_string_literal: true

module Gitlab
  module Kas
    class Client
      TIMEOUT = 2.seconds.freeze
      JWT_AUDIENCE = 'gitlab-kas'

      STUB_CLASSES = {
        configuration_project: Gitlab::Agent::ConfigurationProject::Rpc::ConfigurationProject::Stub
      }.freeze

      ConfigurationError = Class.new(StandardError)

      def initialize
        raise ConfigurationError, 'GitLab KAS is not enabled' unless Gitlab::Kas.enabled?
        raise ConfigurationError, 'KAS internal URL is not configured' unless Gitlab::Kas.internal_url.present?
      end

      def list_agent_config_files(project:)
        request = Gitlab::Agent::ConfigurationProject::Rpc::ListAgentConfigFilesRequest.new(
          repository: repository(project),
          gitaly_address: gitaly_address(project)
        )

        stub_for(:configuration_project)
          .list_agent_config_files(request, metadata: metadata)
          .config_files
          .to_a
      end

      private

      def stub_for(service)
        @stubs ||= {}
        @stubs[service] ||= STUB_CLASSES.fetch(service).new(kas_endpoint_url, credentials, timeout: TIMEOUT)
      end

      def repository(project)
        gitaly_repository = project.repository.gitaly_repository

        Gitlab::Agent::Modserver::Repository.new(gitaly_repository.to_h)
      end

      def gitaly_address(project)
        connection_data = Gitlab::GitalyClient.connection_data(project.repository_storage)

        Gitlab::Agent::Modserver::GitalyAddress.new(connection_data)
      end

      def kas_endpoint_url
        Gitlab::Kas.internal_url.sub(%r{^grpc://|^grpcs://}, '')
      end

      def credentials
        if URI(Gitlab::Kas.internal_url).scheme == 'grpcs'
          GRPC::Core::ChannelCredentials.new
        else
          :this_channel_is_insecure
        end
      end

      def metadata
        { 'authorization' => "bearer #{token}" }
      end

      def token
        JSONWebToken::HMACToken.new(Gitlab::Kas.secret).tap do |token|
          token.issuer = Settings.gitlab.host
          token.audience = JWT_AUDIENCE
        end.encoded
      end
    end
  end
end
