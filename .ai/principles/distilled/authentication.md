---
source_checksum: 5358c8252b33ecac
distilled_at_sha: 3378d9de7ce956458ecfbc5e1845591fa87448fc
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Authentication Principles

## Checklist

### Request Flow and Token Resolution

- DO NOT change the token resolution order in `AuthFinders` (`lib/gitlab/auth/auth_finders.rb`); deploy tokens, bearer tokens, job tokens, and sessions are checked in a specific priority — reordering can cause one token type to shadow another.
- DO NOT implement custom API authentication; use `API::APIGuard` (`lib/api/api_guard.rb`).
- DO NOT hand-roll JWT or token parsing; use `Authn::IamService::JwtValidationService`.
- DO NOT use `lib/gitlab/auth/request_authenticator.rb` for access control; it is for `Rack::Attack` and logging only.
- Use `check_rate_limit!` for rate limiting on token creation and verification endpoints.

### Token Prefixes and Storage

- Use token prefixes to identify token types: `glpat-` (PAT), `gldt-` (deploy token), `glcbt-` (CI job token), `gloas-` (OAuth application secret).
- DO NOT create ad-hoc token columns or manual hashing; use the `TokenAuthenticatable` concern with `add_authentication_token_field`.
- DO NOT add new token types with `insecure: true` storage strategy; use `digest: true` for SHA-256 or `encrypted: :required` for AES-256-GCM encryption at rest.
- Default to expiration on new token types; DO NOT allow token creation without an expiration unless explicitly required.
- DO NOT accept tokens via URL query parameters in new endpoints; use the `PRIVATE-TOKEN` header for PATs or `Authorization: Bearer` for OAuth.
- Compare token equality using a constant-time function (`ActiveSupport::SecurityUtils.secure_compare`) to defend against timing attacks.

### Sessions and Sign-In

- DO NOT create parallel session stores; use Devise combined with `ActiveSession`.
- Use `Rack::Attack` (`config/initializers/rack_attack.rb`) for login throttling.
- Use `Gitlab::ApplicationRateLimiter` for feature-level rate limits (for example, token creation, password resets).
- Ensure every endpoint that validates a credential (password, token, 2FA code, recovery code) is rate-limited; rate-limit keying must include the credential subject (login or user) when feasible, not only the source IP — per-IP-only throttles that reset on success are bypassable via credential stuffing.
- Regenerate the session ID on any privilege change: sign-in, 2FA pass, password change, admin-mode entry — defends against session fixation.

### Access Tokens

- DO NOT change token expiration logic during rotation; token rotation must preserve the original expiration policy (past incidents: rotating a PAT altered service account expiration dates and group membership expiration).
- When blocking a user, verify all active tokens are invalidated across all subsystems (past incident: blocked user PATs continued to mint valid container registry JWTs).

### CI Job Tokens

- DO NOT store CI job tokens in plaintext or compare them with string equality; they are JWTs signed with RSA.
- DO NOT extend CI job token lifetime beyond the job duration; they are scoped to a specific pipeline job and expire with the job.

### OAuth and OIDC

- DO NOT add new OIDC claims without considering data exposure; each claim is included in ID tokens visible to the requesting application.
- DO NOT log, expose, or rotate the OIDC signing key (`openid_connect_signing_key`) without coordinating with the infrastructure team; it is stored in Rails credentials.
- Always create OAuth tokens with an expiration; keep the expiration as short as possible.
- DO NOT implement custom OAuth flows; use OmniAuth strategies for external providers and Doorkeeper for the provider side.
- Use PKCE when GitLab acts as an OAuth client.

### SAML

- Validate SAML `RelayState` parameters before using them as redirect targets (past incident: open redirect via unvalidated RelayState in SAML Single Logout).
- Validate the XML signature on every SAML response and verify the signed element is the assertion being trusted — defends against XML signature wrapping (past incident: [#486565](https://gitlab.com/gitlab-org/gitlab/-/issues/486565) — unauthenticated SAML sign-in bypass).

### Identity Linking and extern_uid

- DO NOT resolve users solely by `extern_uid` without verifying the identity is trusted (the provider must establish that the UID belongs to the account).

### Two-Factor Authentication

- Sanitize login parameters (username, email) before authentication (past incident: whitespace in login parameter bypassed WebAuthn 2FA — [#585333](https://gitlab.com/gitlab-org/gitlab/-/work_items/585333)).
- When a passkey or 2FA device is deleted, invalidate all sessions that were authenticated with that credential.
- DO NOT allow `read_api` or other limited-scope tokens to bypass sudo mode or elevated authentication requirements.

### Password Management

- Use `InternalRedirect#sanitize_redirect` or `safe_redirect_path` to validate all user-supplied redirect targets in password reset flows; DO NOT pass raw parameters to `redirect_to` — always provide a fallback: `redirect_to sanitize_redirect(params[:redirect]) || root_path`.
- Ensure password reset tokens are single-use, short-lived, and invalidated on successful use; successful reset must invalidate all other active sessions for the user.
- Ensure the password reset endpoint validates that the email parameter is a single string value and rejects any request where it is provided as an array or other non-string type (past incident: [#436084](https://gitlab.com/gitlab-org/gitlab/-/issues/436084) — account takeover via password reset).
- Ensure sign-in failure and password-reset responses do not differ between "user exists, wrong credential" and "user does not exist" — use the same response body and the same timing to defend against account enumeration.

### Shared Infrastructure and Logging

- DO NOT change the return type or nil-vs-value semantics of authentication methods without auditing all callers.
- Verify all authentication flows still work when modifying shared infrastructure (web, API, OAuth, SAML entry points all share authentication code).
- DO NOT log token values, password values, or session IDs — this includes error messages, audit events, structured logs, and backtraces.
- When modifying user blocking, banning, or deactivation, verify the blocked state is checked at the point of use, not only at login; tokens, sessions, and API access must all respect the blocked state.
- When adding a new authentication path or token type, verify it respects the `user.blocked?` check.
- DO NOT pass raw user-supplied parameters to `redirect_to`; use `InternalRedirect#sanitize_redirect` or `safe_redirect_path` — redirect helpers return `nil` for invalid targets, so always provide a fallback.

### Composite Identity

- Use composite identity for any AI-generated activity on the GitLab platform that performs write actions.
- Ensure the service account used for composite identity has `composite_identity_enforced: true` (must be configured programmatically — not available in the UI).
- Ensure the OAuth application used for composite identity enables the dynamic scope `user:*` (must be configured programmatically — not available in the UI).
- DO NOT use the standard authorization code flow (browser consent) for composite identity service accounts; service accounts are bot users that cannot sign in interactively.
- Ensure composite identity OAuth token scopes include the concrete dynamic scope `user:$ID` for the human user who originated the AI request, plus any required base scopes (for example, `api`).
- Always use `Gitlab::Auth::Identity.resolve_composite_identity_actor(current_user)` to resolve the actor for any write operation; DO NOT determine the composite identity context manually.
- Use the actor returned by `resolve_composite_identity_actor` wherever authorship is set (notes, system notes, pipeline user context). Exception: DO NOT use `resolve_composite_identity_actor` to set the author of a merge request — the MR author must always be the human user (`current_user` before composite identity resolution), even in the `:authentication` context, to preserve the self-approval guard (`merge_requests_author_approval` defaults to false).
- For human-initiated Git CLI commits in the `:authentication` context, set the human user as the commit `committer` and the service account as the commit `author`; DO NOT swap these roles — keeping the human as committer preserves segregation of duties when `merge_requests_disable_committers_approval` is enabled. Exception: for autonomous triggers with no human initiator, set the service account as both commit `author` and `committer`.
- Understand attribution context: OAuth/CI flows tag `:authentication` context (service account is attributed); web/assignment flows tag `:permission_check` context (human is attributed) — DO NOT override this context manually. In the `:authentication` context, audit events store `author_name` as `<service account name> on behalf of @<human username>` truncated to 255 characters, and record `human_author_id`, `human_author_name`, and `human_author_username` in event `details`; in the `:permission_check` context the human remains the author and no `human_author_*` keys are added (GitLab 19.3 and later).
- Link at most one service account with `:authentication` per request; linking a second raises `Gitlab::Auth::Identity::TooManyIdentitiesLinkedError`. Allow any number of `:permission_check` links.
- Account for `Gitlab::Auth::Identity.currently_linked` selecting the authenticated identity, or the most recently linked identity when none is authenticated. When no authenticated identity exists, link the intended service account immediately before starting its work, because background jobs carry only one identity.

### Feature Flags

- Use `group: group::authentication` for authentication feature flags.

## Authoritative sources

For the full picture, see:

- doc/development/authentication.md
- doc/development/ai_features/composite_identity.md

