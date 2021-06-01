# frozen_string_literal: true

module Mattermost
  class NoSessionError < ::Mattermost::Error
    def message
      'No session could be set up, is Mattermost configured with Single Sign On?'
    end
  end

  ConnectionError = Class.new(::Mattermost::Error)

  # This class' prime objective is to obtain a session token on a Mattermost
  # instance with SSO configured where this GitLab instance is the provider.
  #
  # The process depends on OAuth, but skips a step in the authentication cycle.
  # For example, usually a user would click the 'login in GitLab' button on
  # Mattermost, which would yield a 302 status code and redirects you to GitLab
  # to approve the use of your account on Mattermost. Which would trigger a
  # callback so Mattermost knows this request is approved and gets the required
  # data to create the user account etc.
  #
  # This class however skips the button click, and also the approval phase to
  # speed up the process and keep it without manual action and get a session
  # going.
  class Session
    include Doorkeeper::Helpers::Controller

    LEASE_TIMEOUT = 60

    attr_accessor :current_resource_owner, :token, :base_uri

    def initialize(current_user)
      @current_resource_owner = current_user
      @base_uri = Settings.mattermost.host
    end

    def with_session
      with_lease do
        create

        begin
          yield self
        rescue Errno::ECONNREFUSED => e
          Gitlab::AppLogger.error(e.message + "\n" + e.backtrace.join("\n"))
          raise ::Mattermost::NoSessionError
        ensure
          destroy
        end
      end
    end

    # Next methods are needed for Doorkeeper
    def pre_auth
      @pre_auth ||= Doorkeeper::OAuth::PreAuthorization.new(
        Doorkeeper.configuration, params)
    end

    def authorization
      @authorization ||= strategy.request
    end

    def strategy
      @strategy ||= server.authorization_request(pre_auth.response_type)
    end

    def request
      @request ||= OpenStruct.new(parameters: params)
    end

    def params
      Rack::Utils.parse_query(oauth_uri.query).symbolize_keys
    end

    def get(path, options = {})
      handle_exceptions do
        Gitlab::HTTP.get(path, build_options(options))
      end
    end

    def post(path, options = {})
      handle_exceptions do
        Gitlab::HTTP.post(path, build_options(options))
      end
    end

    def delete(path, options = {})
      handle_exceptions do
        Gitlab::HTTP.delete(path, build_options(options))
      end
    end

    private

    def build_options(options)
      options.tap do |hash|
        hash[:headers] = @headers
        hash[:allow_local_requests] = true
        hash[:base_uri] = base_uri if base_uri.presence
      end
    end

    def create
      raise ::Mattermost::NoSessionError unless oauth_uri
      raise ::Mattermost::NoSessionError unless token_uri

      @token = request_token
      raise ::Mattermost::NoSessionError unless @token

      @headers = {
        Authorization: "Bearer #{@token}"
      }

      @token
    end

    def destroy
      post('/api/v4/users/logout')
    end

    def oauth_uri
      return @oauth_uri if defined?(@oauth_uri)

      @oauth_uri = nil

      response = get('/oauth/gitlab/login', follow_redirects: false)
      return unless (300...400) === response.code

      redirect_uri = response.headers['location']
      return unless redirect_uri

      oauth_cookie = parse_cookie(response)
      @headers = {
        Cookie: oauth_cookie.to_cookie_string
      }

      @oauth_uri = URI.parse(redirect_uri)
    end

    def token_uri
      @token_uri ||=
        if oauth_uri
          authorization.authorize.redirect_uri if pre_auth.authorizable?
        end
    end

    def request_token
      response = get(token_uri, follow_redirects: false)

      if (200...400) === response.code
        response.headers['token']
      end
    end

    def with_lease
      lease_uuid = lease_try_obtain
      raise NoSessionError unless lease_uuid

      begin
        yield
      ensure
        Gitlab::ExclusiveLease.cancel(lease_key, lease_uuid)
      end
    end

    def lease_key
      "mattermost:session"
    end

    def lease_try_obtain
      lease = ::Gitlab::ExclusiveLease.new(lease_key, timeout: LEASE_TIMEOUT)
      lease.try_obtain
    end

    def handle_exceptions
      yield
    rescue Gitlab::HTTP::Error => e
      raise ::Mattermost::ConnectionError, e.message
    rescue Errno::ECONNREFUSED => e
      raise ::Mattermost::ConnectionError, e.message
    end

    def parse_cookie(response)
      cookie_hash = Gitlab::HTTP::CookieHash.new
      response.get_fields('Set-Cookie').each { |c| cookie_hash.add_cookies(c) }
      cookie_hash
    end
  end
end
