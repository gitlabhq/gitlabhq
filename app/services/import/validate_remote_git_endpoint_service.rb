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
      ensure_auth_credentials!

      return ServiceResponse.success if Gitlab::GitalyClient::RemoteService.exists?(uri.to_s) # rubocop: disable CodeReuse/ActiveRecord -- false positive

      ServiceResponse.error(
        message: 'Unable to access repository with the URL and credentials provided',
        reason: 400
      )
    end

    private

    def ensure_auth_credentials!
      return unless user && password

      uri.user = user
      uri.password = password
    end
  end
end
