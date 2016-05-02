class JwtController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  SERVICES = {
    'docker' => Jwt::DockerAuthenticationService,
  }

  def auth
    @authenticated = authenticate_with_http_basic do |login, password|
      @ci_project = ci_project(login, password)
      @user = authenticate_user(login, password) unless @ci_project
    end

    unless @authenticated
      head :forbidden if ActionController::HttpAuthentication::Basic.has_basic_credentials?(request)
    end

    service = SERVICES[params[:service]]
    head :not_found unless service

    result = service.new(@ci_project, @user, auth_params).execute
    return head result[:http_status] if result[:http_status]

    render json: result
  end

  private

  def auth_params
    params.permit(:service, :scope, :offline_token, :account, :client_id)
  end

  def ci_project(login, password)
    matched_login = /(?<s>^[a-zA-Z]*-ci)-token$/.match(login)

    if matched_login.present?
      underscored_service = matched_login['s'].underscore

      if underscored_service == 'gitlab_ci'
        Project.find_by(builds_enabled: true, runners_token: password)
      end
    end
  end

  def authenticate_user(login, password)
    user = Gitlab::Auth.new.find(login, password)

    # If the user authenticated successfully, we reset the auth failure count
    # from Rack::Attack for that IP. A client may attempt to authenticate
    # with a username and blank password first, and only after it receives
    # a 401 error does it present a password. Resetting the count prevents
    # false positives from occurring.
    #
    # Otherwise, we let Rack::Attack know there was a failed authentication
    # attempt from this IP. This information is stored in the Rails cache
    # (Redis) and will be used by the Rack::Attack middleware to decide
    # whether to block requests from this IP.
    config = Gitlab.config.rack_attack.git_basic_auth

    if config.enabled
      if user
        # A successful login will reset the auth failure count from this IP
        Rack::Attack::Allow2Ban.reset(request.ip, config)
      else
        banned = Rack::Attack::Allow2Ban.filter(request.ip, config) do
          # Unless the IP is whitelisted, return true so that Allow2Ban
          # increments the counter (stored in Rails.cache) for the IP
          if config.ip_whitelist.include?(request.ip)
            false
          else
            true
          end
        end

        if banned
          Rails.logger.info "IP #{request.ip} failed to login " \
              "as #{login} but has been temporarily banned from Git auth"
        end
      end
    end

    user
  end
end
