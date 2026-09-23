# frozen_string_literal: true

module Authn
  module TokenExchange
    # Issues short-lived JWTs that GitLab Rails hands to clients for use with
    # modular services (e.g. Artifact Registry). Reuses the instance's
    # `CloudConnector::Keys` keypair as the signing key only; the token shape
    # itself is purpose-built for the GATE-direction token-exchange flow.
    #
    # Will eventually be superseded by GATE L2's `iam-sts` (see ADR-016 / ADR-019).
    class TokenIssuer
      SIGNING_ALGORITHM = 'RS256'

      # Identifies the JWT's shape (stateless, no DB row) to a verifier, so
      # the `glsat-` prefix isn't the only signal of that: the prefix sits
      # outside the signature and isn't tamper-proof on its own.
      TOKEN_TYPE = 'stateless_access_token'

      DEFAULT_TTL_SECONDS = 5.minutes.to_i

      # Bumped only on breaking (non-additive) changes.
      SCHEMA_VERSION = 1

      # .com-only at launch, so always ORGANIZATION; SM/federated origins TBD.
      ORIGIN_ORGANIZATION = 'organization'
      IDENTITY_KIND_USER = 'user'

      # Opt-in audience for callers whose modular service (e.g. AR) needs the
      # Relationships/Lookup API. Verified by membership on each service.
      DATA_ACCESS_AUDIENCE = 'gitlab-iam-data-access'

      # Reuses RoutableToken's key list so the two allowlists can't drift
      # apart (see https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/routable_tokens/#meaning-of-fields).
      ROUTING_CLAIM_KEYS = ::Authn::TokenField::Generator::RoutableToken::VALID_ROUTING_KEYS

      # Values for the binary gitlab.organization_role claim (see #organization_role).
      OWNER_ROLE = 'owner'
      MEMBER_ROLE = 'member'

      # Whether this edition can sign tokens at all; see #signing_jwk.
      def self.available?
        false
      end

      # organization is required (not derived from user) because IAM keys a
      # principal's identity on (origin, origin_id, local_id), and organization
      # decides which principal the token resolves to.
      #
      # job's project and commit are emitted as build provenance (ADR-020 R3);
      # they carry no authorization meaning.
      def initialize(
        audiences:, user:, organization:, ttl: DEFAULT_TTL_SECONDS, scopes: [], identities: [], routing: {}, job: nil
      )
        @audiences = Array(audiences).uniq
        raise ArgumentError, 'audiences must not be empty' if @audiences.empty?

        @user = user
        @organization = organization
        @ttl = ttl
        @scopes = Array(scopes).map(&:to_s)
        @identities = Array.wrap(identities)
        @routing = routing
        @job = job
      end

      def token
        jwk = signing_jwk
        header = { typ: 'JWT', kid: jwk.kid }
        JWT.encode(payload, jwk.signing_key, SIGNING_ALGORITHM, header)
      end

      private

      # The signing key comes from Cloud Connector, which is EE-only, so EE
      # supplies it and CE alone has nothing to sign with.
      def signing_jwk
        raise Gitlab::AbstractMethodError, 'no token signing key is available in this edition'
      end

      def payload
        now = Time.current.to_i

        gitlab_claims = {
          token_type: TOKEN_TYPE,
          origin: ORIGIN_ORGANIZATION,
          origin_id: organization_uuid,
          local_id: @user.id,
          identity_kind: IDENTITY_KIND_USER,
          organization_role: organization_role,
          scopes: @scopes.presence,
          identities: @identities.presence,
          job: job_claims
        }.compact

        {
          jti: SecureRandom.uuid,
          iss: Doorkeeper::OpenidConnect.configuration.issuer,
          aud: @audiences,
          sub: @user.to_global_id.to_s,
          iat: now,
          nbf: now,
          exp: now + @ttl,
          ver: SCHEMA_VERSION,
          gitlab: gitlab_claims
        }.merge(routing_claims)
      end

      def job_claims
        return unless @job

        { project_id: @job.project_id, git_commit_sha: @job.sha }
      end

      def routing_claims
        @routing.compact_blank.symbolize_keys.slice(*ROUTING_CLAIM_KEYS).transform_values { |id| id.to_s(36) }
      end

      def organization_uuid
        @organization.uuid
      end

      # Binary `owner` / `member` claim for the bootstrapping case described in
      # AUTH-015 (interim GATE identity mapping): before any role assignments
      # exist in the Relationships datastore, the modular service needs to
      # know whether the caller is an organization owner to authorize the
      # first activation call. Once activation runs, role lookup moves to the
      # Relationships API and this claim is no longer consulted.
      def organization_role
        @user.owns_organization?(@organization) ? OWNER_ROLE : MEMBER_ROLE
      end
    end
  end
end

Authn::TokenExchange::TokenIssuer.prepend_mod
