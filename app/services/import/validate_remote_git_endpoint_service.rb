# frozen_string_literal: true

module Import
  class ValidateRemoteGitEndpointService
    attr_reader :uri, :user, :password

    def initialize(params)
      @params = params
      @uri = Gitlab::Utils.parse_url(@params[:url])
      @user = @params[:user].presence
      @password = @params[:password].presence
    end

    def execute
      if uri && uri.hostname && Project::VALID_IMPORT_PROTOCOLS.include?(uri.scheme)
        ensure_auth_credentials!

        return ServiceResponse.success if Gitlab::GitalyClient::RemoteService.exists?(uri.to_s) # rubocop: disable CodeReuse/ActiveRecord -- false positive
      end

      failure_response
    rescue GRPC::BadStatus
      # There are a several subclasses of GRPC::BadStatus, but in our case the
      # scenario we're interested in the presence of a valid, accessible
      # repository, so this treats them all as equivalent.
      failure_response
    end

    private

    def failure_response
      ServiceResponse.error(
        message: 'Unable to access repository with the URL and credentials provided',
        reason: 400
      )
    end

    def ensure_auth_credentials!
      return unless user && password

      uri.user = user
      uri.password = password
    end
  end
end
