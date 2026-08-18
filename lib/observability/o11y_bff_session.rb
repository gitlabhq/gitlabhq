# frozen_string_literal: true

module Observability
  # Backend-for-frontend (BFF) broker for per-user GitLab -> SigNoz auth.
  #
  # Instead of running the OAuth authorization-code flow inside the embedded
  # SigNoz iframe (which is blocked by third-party-cookie and frame-ancestors
  # restrictions in modern browsers), GitLab brokers the exchange server-to-server:
  #
  #   1. GitLab mints a per-user, GitLab-signed OIDC id_token for the shared
  #      SigNoz OAuth application, on behalf of the already-authenticated
  #      current user. No browser redirect happens. The token carries the
  #      user's Rails-asserted role and this tenant's instance URL as signed
  #      claims (see #signed_id_token) -- not as sibling request fields --
  #      because every tenant shares the same OAuth application/aud, so an
  #      unsigned field can't be trusted to indicate which tenant a token
  #      was minted for or what role its holder should get. The token also
  #      carries a short expiry (BFF_TOKEN_TTL) and a single-use `jti`
  #      claim, so SigNoz can reject a replayed token even if one is
  #      captured off the wire before mTLS enforcement (documentation#142)
  #      is in place -- see documentation#160.
  #   2. GitLab POSTs that id_token to SigNoz's BFF endpoint
  #      (POST /api/v1/complete/gitlab/bff), presenting a client certificate
  #      over mTLS.
  #   3. SigNoz verifies the id_token against GitLab's JWKS, confirms the
  #      signed instance claim matches its own configured external_url,
  #      self-resolves its single gitlab_auth domain, JIT-provisions the
  #      per-user account using the signed role claim, and returns a
  #      per-user session.
  #   4. GitLab returns those tokens to app.vue, which injects them into the
  #      iframe over the existing O11Y_JWT_LOGIN postMessage channel.
  #
  # One shared GitLab OAuth application is used for every SigNoz instance
  # (referenced via Gitlab::CurrentSettings.o11y_oauth_application) -- see
  # https://gitlab.com/gitlab-org/embody-team/experimental-observability/documentation/-/work_items/138
  # for the full set of design decisions this implements.
  class O11yBffSession
    ConfigurationError = Class.new(StandardError)
    AuthenticationError = Class.new(StandardError)
    NetworkError = Class.new(StandardError)

    # Raised when a user reaches this code path with less than Developer
    # access. The read_observability_portal authorization check (enforced by
    # the calling controller) should already have rejected Reporter/Guest --
    # if this is ever raised, that authorization check has a bug.
    UnexpectedRoleError = Class.new(StandardError)

    BFF_PATH = '/api/v1/complete/gitlab/bff'
    OIDC_SCOPES = 'openid profile email'

    # Namespaced custom id_token claims carrying the values SigNoz's BFF
    # endpoint must trust: the asserted role, and which tenant (instance) the
    # token was minted for. Namespaced to match the `https://gitlab.org/claims/...`
    # convention already used for group claims in
    # config/initializers/doorkeeper_openid_connect.rb, and to avoid
    # colliding with any standard or future OIDC claim. See
    # https://gitlab.com/gitlab-org/embody-team/experimental-observability/documentation/-/work_items/159
    O11Y_ROLE_CLAIM = 'https://gitlab.org/claims/o11y/role'
    O11Y_INSTANCE_CLAIM = 'https://gitlab.org/claims/o11y/instance'

    # BFF_TOKEN_TTL bounds how long a minted id_token is usable at all
    # (verified via the standard OIDC `exp` claim SigNoz already checks).
    # The BFF exchange is a single synchronous request/response -- there is
    # no legitimate reason for the same id_token to be presented twice, so a
    # short TTL plus the jti replay guard (see #signed_id_token) together
    # bound the damage window if a token is captured off the wire (e.g. by a
    # network-position attacker) before mTLS (documentation#142/#160) is in
    # place: a captured token is only replayable within this window, and
    # SigNoz's jti cache (documentation#160 Tier 0) rejects a second use
    # even inside it.
    BFF_TOKEN_TTL = 30.seconds

    ROLE_MAPPING = {
      ::Gitlab::Access::OWNER => 'ADMIN',
      ::Gitlab::Access::MAINTAINER => 'EDITOR',
      ::Gitlab::Access::DEVELOPER => 'EDITOR'
    }.freeze

    TokenResponse = Struct.new(:access_jwt, :refresh_jwt, keyword_init: true) do
      def self.from_json(data)
        data ||= {}
        new(
          access_jwt: data.dig('data', 'accessToken'),
          refresh_jwt: data.dig('data', 'refreshToken')
        )
      end

      def present?
        access_jwt.present? && refresh_jwt.present?
      end

      def to_h
        { accessJwt: access_jwt, refreshJwt: refresh_jwt }
      end
    end

    def self.generate_tokens(o11y_settings:, user:, access_resource:)
      new(o11y_settings: o11y_settings, user: user, access_resource: access_resource).generate_tokens
    end

    def initialize(o11y_settings:, user:, access_resource:)
      @o11y_settings = o11y_settings
      @user = user
      @access_resource = access_resource
    end

    def generate_tokens
      validate!

      # Resolve the role before minting anything: if this raises
      # UnexpectedRoleError, we neither waste a Doorkeeper access token mint
      # nor want that error rewrapped as AuthenticationError by
      # mint_gitlab_assertion's catch-all rescue.
      role = signoz_role
      assertion = mint_gitlab_assertion(role)
      response = exchange_with_signoz(assertion)
      parse_response(response)
    rescue ConfigurationError, AuthenticationError, NetworkError => e
      Gitlab::ErrorTracking.log_exception(e)
      {}
    rescue UnexpectedRoleError => e
      # Unlike the errors above (expected, operational failures -- bad config,
      # a flaky network, SigNoz being down), this indicates the upstream
      # read_observability_portal authorization check let a sub-Developer
      # user reach this class at all -- an invariant violation, not a
      # runtime hiccup. Track it distinctly so it pages/alerts rather than
      # blending into ordinary "SigNoz was unreachable" noise.
      Gitlab::ErrorTracking.track_exception(e, user_id: user.id)
      {}
    end

    private

    attr_reader :o11y_settings, :user, :access_resource

    def validate!
      raise ConfigurationError, 'O11y settings are not set' if o11y_settings.blank?
      raise ConfigurationError, 'user is required' if user.blank?
      raise ConfigurationError, 'o11y_service_url is not configured' if o11y_settings.o11y_service_url.blank?
      raise ConfigurationError, 'o11y_service_url is not a valid HTTPS URL' unless valid_o11y_service_url?
      raise ConfigurationError, 'group is not configured' if group.blank?
      raise ConfigurationError, 'access_resource is required' if access_resource.blank?
      raise ConfigurationError, 'SigNoz OAuth application is not configured' if o11y_application.blank?
    end

    # o11y_service_url is signed into the id_token (see #signed_id_token) and
    # sent as the `ref` field SigNoz uses to build its session-state redirect
    # (see #build_payload) -- both consequential enough that a malformed or
    # non-HTTPS value should hard-fail here rather than propagate. The model
    # already enforces this shape on save (GroupO11ySetting's addressable_url
    # validator), so this is defense-in-depth against stale/edge-case
    # records rather than the primary guard.
    def valid_o11y_service_url?
      uri = URI.parse(o11y_settings.o11y_service_url)
      return uri.is_a?(URI::HTTP) && uri.host.present? if Rails.env.development?

      uri.is_a?(URI::HTTPS) && uri.host.present?
    rescue URI::InvalidURIError
      false
    end

    def group
      o11y_settings.group
    end

    # Only Developer+ users are ever authorized to reach this code path --
    # the read_observability_portal authorization check (config/authz/roles/*)
    # rejects Reporter/Guest before O11yBffSession is invoked at all. So the
    # role sent to SigNoz only ever needs Owner->ADMIN or
    # Maintainer/Developer->EDITOR. If max_member_access_for_user ever
    # resolves below Developer here, that's a bug in the upstream
    # authorization check, not a case to silently degrade for.
    #
    # The role is resolved against access_resource -- the same subject the
    # calling controller passed to its read_observability_portal Ability
    # check -- so role resolution follows the same access paths (ancestor
    # membership, group shares, project team membership) the policy layer
    # used to authorize the request. Resolving against a different subject
    # (e.g. always the setting's namespace) would 401 users the policy
    # legitimately authorized, such as members of a personal-namespace
    # project who are not the namespace owner.
    def signoz_role
      access_level = access_resource.max_member_access_for_user(user)
      role = ROLE_MAPPING[access_level]

      if role.blank?
        raise UnexpectedRoleError,
          "user #{user.id} resolved to access level #{access_level} " \
            "on #{access_resource.class.name} #{access_resource.id}, " \
            "below the Developer minimum required to reach O11yBffSession"
      end

      role
    end

    # Mints a per-user, GitLab-signed OIDC id_token for the SigNoz OAuth
    # application, entirely server-side. Returns { id_token: }.
    #
    # The token carries two SigNoz-specific claims -- role and instance --
    # signed alongside the standard OIDC claims, rather than sent as sibling
    # fields in the request body. SigNoz's BFF endpoint is OpenAccess (no
    # SigNoz-side session required), so any value sent outside the signed
    # token is attacker-controlled: without this, a user could POST any
    # id_token they can legitimately obtain (e.g. from the ordinary browser
    # OIDC flow, against the same shared OAuth application) together with
    # a self-asserted role and a ref pointing at a different tenant, and
    # SigNoz would grant them that role on an instance they have no
    # relationship to -- the shared-OAuth-app model gives every tenant the
    # same aud, so nothing about the token itself indicates which tenant it
    # was minted for. Signing role + instance closes that: SigNoz derives
    # both only from the verified signature, never from caller-supplied
    # request fields. See
    # https://gitlab.com/gitlab-org/embody-team/experimental-observability/documentation/-/work_items/159
    #
    # Isolated as a single seam so the Doorkeeper/OIDC integration can be
    # verified against the running instance and stubbed in specs.
    def mint_gitlab_assertion(role)
      # NOTE: OauthAccessToken (GitLab's Doorkeeper::AccessToken subclass) requires
      # `organization` (belongs_to, not optional). Reuse the SigNoz application's
      # own organization rather than guessing/hardcoding one.
      access_token = Doorkeeper::AccessToken.create!(
        application: o11y_application,
        organization: o11y_application.organization,
        resource_owner_id: user.id,
        scopes: OIDC_SCOPES,
        expires_in: 5.minutes.to_i,
        use_refresh_token: false
      )

      id_token = signed_id_token(access_token, role)

      { id_token: id_token }
    rescue Doorkeeper::Errors::DoorkeeperError, ActiveRecord::ActiveRecordError, JWT::EncodeError => e
      raise AuthenticationError, "Failed to mint GitLab assertion: #{e.message}"
    ensure
      # We only need the id_token; avoid leaving a live access token sitting
      # around for a flow that never uses it. Rescue inside the ensure so a
      # revocation failure (e.g. a DB error) is logged and observable rather
      # than silently replacing any in-flight exception.
      begin
        access_token&.revoke
      rescue StandardError => e
        Gitlab::ErrorTracking.log_exception(e, user_id: user.id)
      end
    end

    # Builds the same claim set Doorkeeper::OpenidConnect::IdToken#as_jws_token
    # would produce, then merges in the SigNoz-specific role/instance claims
    # plus a standard `jti` (JWT ID) before signing with GitLab's own OIDC
    # signing key. Namespaced claim names (matching the
    # `https://gitlab.org/claims/...` convention already used for group
    # claims in config/initializers/doorkeeper_openid_connect.rb) avoid
    # colliding with any standard or future OIDC claim.
    #
    # `jti` + the short BFF_TOKEN_TTL together give SigNoz what it needs to
    # reject a replayed token (documentation#160 Tier 0): SigNoz tracks seen
    # jtis in a short-TTL cache and rejects a repeat, closing the window
    # where a network-position attacker who captures a legitimately-minted
    # id_token (e.g. before mTLS enforcement lands, documentation#142) could
    # replay it against the BFF endpoint. `jti` uses SecureRandom rather
    # than being derived from any request data, since it exists purely as a
    # single-use nonce.
    def signed_id_token(access_token, role)
      base_claims = ::Doorkeeper::OpenidConnect::IdToken.new(access_token, nil, BFF_TOKEN_TTL).as_json

      claims = base_claims.merge(
        'jti' => SecureRandom.uuid,
        O11Y_ROLE_CLAIM => role,
        O11Y_INSTANCE_CLAIM => o11y_settings.o11y_service_url
      )

      ::JWT.encode(
        claims,
        ::Doorkeeper::OpenidConnect.signing_key.keypair,
        ::Doorkeeper::OpenidConnect.signing_algorithm.to_s,
        { typ: 'JWT', kid: ::Doorkeeper::OpenidConnect.signing_key.kid }
      )
    end

    def exchange_with_signoz(assertion)
      Gitlab::HTTP.post(
        bff_url,
        **mtls_options,
        headers: { 'Content-Type' => 'application/json' },
        body: Gitlab::Json.dump(build_payload(assertion)),
        allow_local_requests: allow_local_requests?
      )
    rescue *Gitlab::HTTP::HTTP_ERRORS => e
      raise NetworkError, "Failed to connect to O11y service (#{e.class.name}): #{e.message}"
    end

    def allow_local_requests?
      Rails.env.development? ||
        Rails.env.test? ||
        ::Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
    end

    # role and instance binding travel as signed claims inside idToken (see
    # #signed_id_token) -- SigNoz derives both from the verified token, never
    # from this request body. ref is retained only to tell SigNoz which
    # frontend origin to build the session-state redirect for; it carries no
    # authorization weight. See
    # https://gitlab.com/gitlab-org/embody-team/experimental-observability/documentation/-/work_items/159
    def build_payload(assertion)
      {
        idToken: assertion[:id_token],
        ref: o11y_settings.o11y_service_url
      }
    end

    # The BFF endpoint sits behind a dedicated ALB listener in mTLS "Verify
    # with trust store" mode, on a different host/port than the instance's
    # normal o11y_service_url (used for session-context/UI calls). Both the
    # listener and the client cert/key are net-new infrastructure (see
    # documentation#142) and may not be configured yet -- while bff_mtls is
    # disabled we fall back to o11y_service_url with no client cert, which
    # will simply be rejected by SigNoz once the mTLS listener is enforced.
    #
    # bff_url and mtls_options both gate on mtls_fully_configured? (rather
    # than each independently checking listener vs. cert config) so the two
    # never disagree: we either target the dedicated listener with the
    # client cert attached, or (mTLS disabled) the plain o11y_service_url
    # with no cert. A partial configuration with mTLS enabled raises
    # ConfigurationError instead of degrading -- see mtls_fully_configured?.
    def bff_url
      return URI.join(o11y_settings.o11y_service_url, BFF_PATH).to_s unless mtls_fully_configured?

      uri = URI.parse(o11y_settings.o11y_service_url)
      uri.host = mtls_config.listener_host
      uri.port = mtls_config.listener_port
      URI.join(uri.to_s, BFF_PATH).to_s
    end

    def mtls_options
      return {} unless mtls_fully_configured?

      { pem: mtls_pem }
    end

    # Fails closed: the `enabled` flag expresses operator intent. When it is
    # set but any part of the configuration is missing (listener host/port
    # unset, cert files absent), we raise rather than silently falling back
    # to the plain o11y_service_url with no client cert -- otherwise a cert
    # rotation failure or config drift after mTLS enforcement would quietly
    # revert this exchange to an unprotected channel with only a log warning
    # to show for it. With `enabled: false` the fallback is intentional
    # (the mTLS listener is net-new infrastructure, documentation#142, and
    # does not exist yet for most instances).
    def mtls_fully_configured?
      return @mtls_fully_configured if defined?(@mtls_fully_configured)
      return @mtls_fully_configured = false unless mtls_config.enabled

      listener = mtls_listener_configured?
      cert = mtls_client_cert_configured?

      unless listener && cert
        raise ConfigurationError,
          "O11y BFF mTLS is enabled but incompletely configured " \
            "(listener configured: #{listener}, client cert configured: #{cert})"
      end

      @mtls_fully_configured = true
    end

    def mtls_pem
      @mtls_pem ||= [
        File.read(mtls_config.certificate_file),
        File.read(mtls_config.private_key_file)
      ].join("\n")
    rescue Errno::ENOENT, Errno::EACCES => e
      raise ConfigurationError, "Failed to read mTLS client certificate files: #{e.message}"
    end

    def mtls_config
      Gitlab.config.observability.bff_mtls
    end

    def mtls_listener_configured?
      mtls_config.listener_host.present? && mtls_config.listener_port.present?
    end

    def mtls_client_cert_configured?
      mtls_config.certificate_file.present? &&
        mtls_config.private_key_file.present? &&
        File.exist?(mtls_config.certificate_file) &&
        File.exist?(mtls_config.private_key_file)
    end

    def parse_response(response)
      if response.code.to_i != 200
        Gitlab::AppLogger.warn(
          message: 'O11y BFF session exchange failed',
          Labkit::Fields::CLASS_NAME => self.class.name,
          response_code: response.code
        )

        return {}
      end

      body = response.body.to_s.strip
      raise AuthenticationError, 'Empty response from O11y service' if body.blank?

      data = Gitlab::Json::SafeParser.parse(body)
      tokens = TokenResponse.from_json(data)
      return {} unless tokens.present?

      tokens.to_h
    rescue JSON::ParserError => e
      raise AuthenticationError, "Invalid response format from O11y service: #{e.message}"
    end

    def o11y_application
      Gitlab::CurrentSettings.o11y_oauth_application
    end
  end
end
