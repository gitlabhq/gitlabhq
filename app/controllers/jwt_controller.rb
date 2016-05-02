class JwtController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def auth
    @authenticated = authenticate_with_http_basic do |login, password|
      @ci_project = ci_project(login, password)
      @user = authenticate_user(login, password) unless @ci_project
    end

    unless @authenticated
      return render_403 if has_basic_credentials?
    end

    case params[:service]
    when 'docker'
      docker_token_auth(params[:scope], params[:offline_token])
    else
      return render_404
    end
  end

  private

  def render_400
    head :invalid_request
  end

  def render_404
    head :not_found
  end

  def render_403
    head :forbidden
  end

  def docker_token_auth(scope, offline_token)
    payload = {
      aud: params[:service],
      sub: @user.try(:username)
    }

    if offline_token
      return render_403 unless @user
    elsif scope
      access = process_access(scope)
      return render_404 unless access
      payload[:access] = [access]
    end

    render json: { token: encode(payload) }
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

  def process_access(scope)
    type, name, actions = scope.split(':', 3)
    actions = actions.split(',')

    case type
    when 'repository'
      process_repository_access(type, name, actions)
    end
  end

  def process_repository_access(type, name, actions)
    project = Project.find_with_namespace(name)
    return unless project

    actions = actions.select do |action|
      can_access?(project, action)
    end

    { type: 'repository', name: name, actions: actions } if actions
  end

  def default_payload
    {
      aud: 'docker',
      sub: @user.try(:username),
      aud: params[:service],
    }
  end

  def private_key
    @private_key ||= OpenSSL::PKey::RSA.new File.read Gitlab.config.registry.key
  end

  def encode(payload)
    issued_at = Time.now
    payload = payload.merge(
      iss: Gitlab.config.registry.issuer,
      iat: issued_at.to_i,
      nbf: issued_at.to_i - 5.seconds.to_i,
      exp: issued_at.to_i + 60.minutes.to_i,
      jti: SecureRandom.uuid,
    )
    headers = {
      kid: kid(private_key)
    }
    JWT.encode(payload, private_key, 'RS256', headers)
  end

  def can_access?(project, action)
    case action
    when 'pull'
      project == @ci_project || can?(@user, :download_code, project)
    when 'push'
      project == @ci_project || can?(@user, :push_code, project)
    else
      false
    end
  end

  def kid(private_key)
    sha256 = Digest::SHA256.new
    sha256.update(private_key.public_key.to_der)
    payload = StringIO.new(sha256.digest).read(30)
    Base32.encode(payload).split('').each_slice(4).each_with_object([]) do |slice, mem|
      mem << slice.join
    end.join(':')
  end
end
