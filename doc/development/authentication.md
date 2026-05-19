---
stage: Software Supply Chain Security
group: Authentication
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Authentication development guidelines
---

The Authentication team owns two feature categories: **System Access** and
**User Profile**. This guide covers the key topics under these categories
with where to look and what to watch out for.

For in-depth security knowledge about authentication and authorization at
GitLab, see the
[Authentication & Authorization Security Knowledge Base](https://gitlab.com/gitlab-com/content-sites/internal-handbook/-/blob/main/content/handbook/security/product_security/application_security/authn-authz-security-knowledge.md)
(internal).

## Request flow overview

All authentication flows converge on `current_user`:

```plaintext
HTTP Request
    │
    ▼
Rack Middleware (Labkit → Rack::Attack → Warden → CSRF)
    │
    ├── Web Request ──► SessionsController / OmniauthCallbacks ──► Warden Strategies
    │
    └── API Request ──► API::APIGuard ──► AuthFinders (token lookup)
                                              │
                                              ▼
                                         current_user
```

For API requests, `AuthFinders` (`lib/gitlab/auth/auth_finders.rb`)
checks authentication sources in this order:

1. Deploy token
1. Bearer token (job token, PAT, or OAuth)
1. Job token (header or parameter)
1. Session fallback (for web-initiated API calls)

Guardrails:

- Do not change the token resolution order in `AuthFinders`. Deploy tokens,
  bearer tokens, job tokens, and sessions are checked in a specific priority.
  Reordering can cause one token type to shadow another.

## Token prefixes

Use token prefixes to identify token types during debugging and code review.

| Prefix | Token type | Storage |
|---|---|---|
| `glpat-` | Personal, project, or group access token | SHA-256 digest |
| `gldt-` | Deploy token | AES-256-GCM encrypted |
| `glcbt-` | CI job token | AES-256-GCM encrypted |
| `gloas-` | OAuth application secret | SHA-512 digest |

For a complete list of token types and storage strategies, see the
[Authentication & Authorization Security Knowledge Base](https://gitlab.com/gitlab-com/content-sites/internal-handbook/-/blob/main/content/handbook/security/product_security/application_security/authn-authz-security-knowledge.md#215-other-authentication-mechanisms)
(internal).

## Sign-in and sessions

Web sign-in uses Devise and Warden. Configuration is in
`config/initializers/8_devise.rb` (the `8_` prefix controls load ordering).

| Where to look | Purpose |
|---|---|
| `app/controllers/sessions_controller.rb` | Web login and logout. |
| `config/initializers/warden.rb` | Warden callbacks, session setup. |
| `app/models/active_session.rb` | Session tracking in Redis. |
| `app/controllers/admin/sessions_controller.rb` | Admin mode authentication. |

Guardrails:

- Do not create parallel session stores. Use Devise combined with `ActiveSession`.
- Use Rack::Attack (`config/initializers/rack_attack.rb`) for login throttling.
- Use `Gitlab::ApplicationRateLimiter` for feature-level rate limits
  (for example, token creation, password resets). For more information, see
  [application rate limiter](application_limits.md#implement-rate-limits-using-gitlabapplicationratelimiter).
- Any endpoint that validates a credential (password, token, 2FA code,
  recovery code) must be rate-limited. Rate-limit keying must include the
  credential subject (login or user) when feasible, not only the source IP.
  Per-IP-only throttles that reset on success are bypassable via
  credential stuffing.
- Regenerate the session ID on any privilege change: sign-in, 2FA pass,
  password change, admin-mode entry. Defends against session fixation.

For more information about session-based authentication, see the
[Authentication & Authorization Security Knowledge Base](https://gitlab.com/gitlab-com/content-sites/internal-handbook/-/blob/main/content/handbook/security/product_security/application_security/authn-authz-security-knowledge.md#211-session-based-authentication)
(internal).

## Access tokens

Personal access tokens (PATs), group access tokens, project access tokens,
and service account PATs are all stored in the `personal_access_tokens`
table and share the same authentication flow. They differ in how they are
created, which user type owns them, and what authorization checks apply
after authentication.

### Personal access tokens

| Where to look | Purpose |
|---|---|
| `app/models/personal_access_token.rb` | PAT model, scopes, expiration validation. |
| `lib/api/personal_access_tokens.rb` | PAT REST API (list, revoke, rotate). |
| `app/controllers/user_settings/personal_access_tokens_controller.rb` | PAT UI. |
| `app/services/personal_access_tokens/` | Create, revoke, rotate services. |

### Group and project access tokens

| Where to look | Purpose |
|---|---|
| `lib/api/resource_access_tokens.rb` | REST API for group/project tokens. |
| `app/services/resource_access_tokens/create_service.rb` | Token creation with bot user provisioning. |
| `app/controllers/groups/settings/access_tokens_controller.rb` | Group token UI. |
| `app/controllers/projects/settings/access_tokens_controller.rb` | Project token UI. |

### Service accounts

Service accounts (`user_type: :service_account`) are dedicated users for
external integrations and automations. They can be provisioned at instance,
group, or project level.

- Only instance admins can create instance-level service accounts
  (`app/services/users/service_accounts/create_service.rb`).
- Only group owners can create group-level service accounts
  (`app/services/namespaces/service_accounts/group_create_service.rb`).
- Project maintainers and above can create project-level service accounts
  (`app/services/namespaces/service_accounts/project_create_service.rb`).
- Service accounts with `composite_identity_enforced: true` are excluded
  from seat counting.

| Where to look | Purpose |
|---|---|
| `lib/api/service_accounts.rb` | Instance SA REST API. |
| `lib/api/group_service_accounts.rb` | Group SA REST API. |
| `lib/api/project_service_accounts.rb` | Project SA REST API. |

### Access token guardrails

- Do not create ad-hoc token columns or manual hashing. Use the
  `TokenAuthenticatable` concern with `add_authentication_token_field`.
  For more information, see
  [Using the `TokenAuthenticatable` concern](token_authenticatable.md).
- Do not add new token types with
  [`insecure: true`](token_authenticatable.md#storage-strategies) storage
  strategy. Use `digest: true` for SHA-256 digest storage or
  `encrypted: :required` for AES-256-GCM encryption at rest. For more
  information, see the
  [Authentication & Authorization Security Knowledge Base](https://gitlab.com/gitlab-com/content-sites/internal-handbook/-/blob/main/content/handbook/security/product_security/application_security/authn-authz-security-knowledge.md#215-other-authentication-mechanisms)
  (internal).
- `MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS` (365) is the default
  expiration applied when no date is provided. It is not enforced as a cap
  when `require_personal_access_token_expiry` is disabled.
- Do not change token expiration logic during rotation. Token rotation
  must preserve the original expiration policy. Past incidents: rotating
  a PAT altered service account expiration dates and group membership
  expiration.
- When blocking a user, verify all active tokens are invalidated across
  all subsystems. Past incident: blocked user PATs continued to mint
  valid container registry JWTs.
- Default to expiration on new token types. Do not allow token creation
  without an expiration unless explicitly required.
- Do not accept tokens via URL query parameters in new endpoints. Use
  `PRIVATE-TOKEN` header for PATs or `Authorization: Bearer` for OAuth.

For more information about access token authentication, see the
[Authentication & Authorization Security Knowledge Base](https://gitlab.com/gitlab-com/content-sites/internal-handbook/-/blob/main/content/handbook/security/product_security/application_security/authn-authz-security-knowledge.md#212-personal-group-project-access-tokens-pats)
(internal).

## CI job tokens

CI job tokens authenticate pipeline jobs to the GitLab API.

| Where to look | Purpose |
|---|---|
| `lib/ci/job_token/jwt.rb` | JWT generation and signing. |
| `lib/gitlab/auth/auth_finders.rb` | Job token extraction and lookup. |
| `app/models/ci/build.rb` | Build model, token storage (encrypted). |
| `ee/app/models/concerns/ee/ci/job_token/jwt.rb` | EE extensions (composite identity). |

Guardrails:

- CI job tokens are JWTs signed with RSA. Do not store them in plaintext
  or compare them with string equality.
- Job tokens are scoped to a specific pipeline job and expire with the job.
  Do not extend their lifetime beyond the job duration.

For more information, see the
[Authentication & Authorization Security Knowledge Base](https://gitlab.com/gitlab-com/content-sites/internal-handbook/-/blob/main/content/handbook/security/product_security/application_security/authn-authz-security-knowledge.md#214-ci-job-tokens)
(internal).

## OAuth and OpenID Connect

GitLab acts as both an OAuth provider and client. GitLab also acts as an
OpenID Connect (OIDC) provider through `doorkeeper-openid_connect`.

### GitLab as OAuth and OIDC provider

External applications authenticate users through GitLab using Doorkeeper.
OIDC adds an identity layer on top of OAuth, issuing ID tokens alongside
access tokens.

| Where to look | Purpose |
|---|---|
| `app/controllers/oauth/authorizations_controller.rb` | Authorization prompt and code generation. |
| `app/controllers/oauth/tokens_controller.rb` | Token exchange endpoint. |
| `app/models/authn/oauth_application.rb` | OAuth application registration. |
| `app/models/oauth_access_token.rb` | Access token storage (Sha512Hash). |
| `config/initializers/doorkeeper.rb` | Doorkeeper configuration, scopes, grant flows. |
| `config/initializers/doorkeeper_openid_connect.rb` | OIDC provider configuration, claims, signing keys. |
| `app/controllers/oauth/discovery_controller.rb` | OIDC discovery endpoint (`/.well-known/openid-configuration`). |

OIDC claims are defined in `doorkeeper_openid_connect.rb`. Standard claims
include `sub`, `name`, `email`, `groups`, and role-based group claims
(`https://gitlab.org/claims/groups/owner`, etc.).

For more information about OAuth at GitLab, see the
[Authentication & Authorization Security Knowledge Base](https://gitlab.com/gitlab-com/content-sites/internal-handbook/-/blob/main/content/handbook/security/product_security/application_security/authn-authz-security-knowledge.md#213-oauth-tokens)
(internal).

Guardrails:

- Do not add new OIDC claims without considering data exposure. Each claim
  is included in ID tokens visible to the requesting application.
- The OIDC signing key (`openid_connect_signing_key`) is stored in
  Rails credentials. Do not log, expose, or rotate it without coordinating
  with the infrastructure team.
- Always create tokens with an expiration. Keep the expiration as short
  as possible.

### GitLab as OAuth client

Users sign in to GitLab through external providers (Google, GitHub, Azure)
using OmniAuth strategies.

| Where to look | Purpose |
|---|---|
| `app/controllers/omniauth_callbacks_controller.rb` | Callback handler for all providers. |
| `lib/gitlab/auth/o_auth/user.rb` | User lookup, creation, identity linking. |
| `lib/gitlab/auth/o_auth/auth_hash.rb` | Parses auth data from provider. |
| `config/initializers/omniauth.rb` | OmniAuth initialization. |

Guardrails:

- Do not implement custom OAuth flows. Use OmniAuth strategies for external
  providers and Doorkeeper for the provider side.
- Use PKCE when GitLab acts as an OAuth client.

## SAML

SAML provides single sign-on through identity providers (Okta, Azure AD).
GitLab supports two SAML modes:

| Aspect | Instance SAML | Group SAML (EE) |
|---|---|---|
| Scope | Entire GitLab instance | Per top-level group |
| Configuration | `gitlab.rb` or `omniauth_providers` | Group Settings UI |
| Routes | `/users/auth/saml` | `/groups/:path/-/saml` |
| Strategy | `omniauth-saml` gem | Custom `GroupSaml` strategy |
| Enforcement | Instance-wide | Per-group SSO enforcement |

| Where to look | Purpose |
|---|---|
| `lib/gitlab/auth/saml/` | Instance-level SAML strategy and identity linker. |
| `ee/lib/gitlab/auth/group_saml/` | Group SAML: user resolution, identity linking, membership updates. |
| `ee/app/controllers/groups/omniauth_callbacks_controller.rb` | Group SAML callback handler. |
| `ee/app/controllers/groups/sso_controller.rb` | Group SSO page. |
| `ee/app/controllers/groups/saml_providers_controller.rb` | SAML provider configuration UI. |
| `ee/lib/api/provider_identity.rb` | API for managing SAML/SCIM identities and extern_uid. |

Guardrails:

- When modifying `extern_uid` through the API, set `trusted_extern_uid` to
  `false`. The base OAuth login class (`lib/gitlab/auth/o_auth/user.rb`)
  checks `trusted_extern_uid?` before resolving the user. When you override
  the user lookup in a subclass, verify the override also checks this flag.
- Validate SAML `RelayState` parameters before using them as redirect
  targets. Past incident: open redirect via unvalidated RelayState in
  SAML Single Logout.
- Validate the XML signature on every SAML response and verify the signed
  element is the assertion being trusted. Defends against XML signature
  wrapping. Past incident:
  [#486565](https://gitlab.com/gitlab-org/gitlab/-/issues/486565) —
  unauthenticated SAML sign-in bypass.

## SCIM

SCIM automates user lifecycle management (provisioning and deprovisioning).
SCIM is for provisioning only and does not handle authentication.

| Where to look | Purpose |
|---|---|
| `ee/app/models/scim_identity.rb` | SCIM identity records. |
| `ee/lib/api/scim/group_scim.rb` | Group SCIM API (RFC 7644). |
| `ee/app/controllers/groups/settings/domain_verification_controller.rb` | Domain verification for SCIM. |

For more information, see [Configure SCIM](../user/group/saml_sso/scim_setup.md).

## LDAP

LDAP authenticates users against directory services (Active Directory,
OpenLDAP).

| Where to look | Purpose |
|---|---|
| `lib/gitlab/auth/ldap/` | LDAP authentication and adapter. |
| `ee/lib/gitlab/auth/ldap/` | EE LDAP sync, group links. |
| `ee/app/controllers/groups/ldaps_controller.rb` | LDAP group sync UI. |
| `ee/lib/api/ldap.rb` | LDAP REST API. |

For more information, see
[Integrate LDAP with GitLab](../administration/auth/ldap/_index.md).

## Two-factor authentication

Two-factor authentication (2FA) adds a second verification step to log in.

| Where to look | Purpose |
|---|---|
| `app/controllers/profiles/two_factor_auths_controller.rb` | 2FA setup UI (TOTP, WebAuthn). |
| `app/controllers/profiles/passkeys_controller.rb` | Passkey management. |
| `app/controllers/concerns/authenticates_with_two_factor.rb` | 2FA enforcement in login flow. |
| `app/controllers/concerns/enforces_two_factor_authentication.rb` | 2FA requirement checks. |

Guardrails:

- Sanitize login parameters (username, email) before authentication.
  Past incident: whitespace in login parameter bypassed WebAuthn 2FA
  ([#585333](https://gitlab.com/gitlab-org/gitlab/-/work_items/585333)).
- When a passkey or 2FA device is deleted, invalidate all sessions
  that were authenticated with that credential.
- Do not allow `read_api` or other limited-scope tokens to bypass
  sudo mode or elevated authentication requirements.

## SSH keys

SSH keys authenticate Git operations over SSH.

| Where to look | Purpose |
|---|---|
| `app/controllers/user_settings/ssh_keys_controller.rb` | SSH key management UI. |
| `lib/api/keys.rb` | SSH key REST API. |
| `app/models/key.rb` | SSH key model and validation. |

## Identity linking and extern_uid

When a user authenticates through an external provider, GitLab creates an
`Identity` record that links the GitLab user to the provider account.

The `Identity` model (`app/models/identity.rb`) stores:

- `user_id`: The GitLab user.
- `provider`: The provider name (for example, `google_oauth2`, `group_saml`,
  `ldapmain`).
- `extern_uid`: The user's unique identifier from the provider.
- `saml_provider_id`: For Group SAML, links to the group's SAML configuration.
- `trusted_extern_uid`: Boolean flag, defaults to `true`. Set to `false`
  when `extern_uid` is modified through the API.

During login, GitLab resolves the user through the identity:

1. The external provider returns an authentication response with a UID.
1. GitLab looks up an `Identity` record matching the provider and UID.
1. If found and trusted, GitLab signs in the linked user.
1. If not found, GitLab creates a new user or prompts for account linking.

Guardrails:

- Do not update `extern_uid` without setting `trusted_extern_uid` to
  `false`. Unverified extern_uid changes can enable account takeover.
- When overriding user lookup in OAuth subclasses (for example,
  `GroupSaml::User`), verify the override checks `trusted_extern_uid?`.
  The base class checks this but overrides can bypass it.
- Do not resolve users solely by `extern_uid` without verifying the
  identity is trusted (`trusted_extern_uid?`).

## Password management

| Where to look | Purpose |
|---|---|
| `app/controllers/passwords_controller.rb` | Password reset flow. |
| `app/controllers/user_settings/passwords_controller.rb` | Password change. |
| `app/models/concerns/recoverable_by_any_email.rb` | Reset via primary or secondary email. |

Guardrails:

- Use `InternalRedirect#sanitize_redirect` or `safe_redirect_path` to
  validate all user-supplied redirect targets in password reset flows.
  Do not pass raw parameters to `redirect_to`. Always provide a fallback:

```ruby
redirect_to sanitize_redirect(params[:redirect]) || root_path
```

- Password reset tokens must be single-use, short-lived, and invalidated
  on successful use. Successful reset must invalidate all other active
  sessions for the user.
- The password reset endpoint must validate that the email parameter is a
  single string value and reject any request where it is provided as an
  array or any other non-string type. Past incident:
  [#436084](https://gitlab.com/gitlab-org/gitlab/-/issues/436084) —
  account takeover via password reset.
- Sign-in failure and password-reset responses must not differ between
  "user exists, wrong credential" and "user does not exist." Use the same
  response body and the same timing. Defends against account enumeration.

## User profile

| Where to look | Purpose |
|---|---|
| `app/controllers/profiles_controller.rb` | Profile display. |
| `app/controllers/user_settings/profiles_controller.rb` | Profile editing. |
| `app/controllers/profiles/emails_controller.rb` | Email management. |
| `app/controllers/profiles/avatars_controller.rb` | Avatar upload. |
| `app/controllers/profiles/preferences_controller.rb` | User preferences. |

## API authentication

API requests authenticate through `API::APIGuard` (`lib/api/api_guard.rb`),
which handles OAuth2 bearer tokens, scope enforcement, DPoP checks, and
error handling.

| Where to look | Purpose |
|---|---|
| `lib/api/api_guard.rb` | API authentication module. |
| `lib/gitlab/auth/auth_finders.rb` | Token lookup for API requests. |
| `lib/gitlab/auth/request_authenticator.rb` | Request identity resolution for Rack::Attack and logging only. Do not use for access control. |
| `app/services/auth/dpop_authentication_service.rb` | DPoP proof-of-possession verification. |

Guardrails:

- Do not implement custom API authentication. Use `API::APIGuard`.
- Do not hand-roll JWT or token parsing. Use
  `Authn::IamService::JwtValidationService`.
- Use `check_rate_limit!` for rate limiting on token creation and
  verification endpoints.

## Shared infrastructure

Authentication code is shared across web, API, OAuth, and SAML entry
points. A change in shared infrastructure can break all flows.

| Where to look | Purpose |
|---|---|
| `app/models/authn/`, `app/services/authn/`, `lib/authn/` | Authentication models, services, token framework. |
| `lib/gitlab/auth/` | Core auth infrastructure. |
| `app/controllers/concerns/internal_redirect.rb` | Safe redirect validation. |

Guardrails:

- Do not change the return type or nil-vs-value semantics of authentication
  methods without auditing all callers.
- Authentication code is shared across all entry points. Verify all flows
  still work when modifying shared infrastructure.
- Never log token values, password values, or session IDs. This includes
  error messages, audit events, structured logs, and backtraces.
- Token equality comparison must use a constant-time function
  (`ActiveSupport::SecurityUtils.secure_compare`). Defends against timing
  attacks on token validation.
- When modifying user blocking, banning, or deactivation, verify the
  blocked state is checked at the point of use, not only at login. Tokens,
  sessions, and API access must all respect the blocked state.
- When adding a new authentication path or token type, verify it respects
  the `user.blocked?` check.
- Do not pass raw user-supplied parameters to `redirect_to`. Use
  `InternalRedirect#sanitize_redirect` or `safe_redirect_path`. Redirect
  helpers return `nil` for invalid targets. Always provide a fallback.

## Feature flags

Use `group: group::authentication` for authentication feature flags.

## Related topics

- [Using the `TokenAuthenticatable` concern](token_authenticatable.md)
- [Authorization development guidelines](permissions.md)
- [Secure coding guidelines](secure_coding_guidelines/_index.md)
- [Authentication and authorization glossary](../auth/auth_glossary.md)
- [OAuth 2.0 identity provider API](../api/oauth2.md)
- [OmniAuth configuration](../integration/omniauth.md)
- [SAML SSO for GitLab.com groups](../user/group/saml_sso/_index.md)
- [Configure SCIM](../user/group/saml_sso/scim_setup.md)
- [Integrate LDAP with GitLab](../administration/auth/ldap/_index.md)
- [Composite identity](ai_features/composite_identity.md)
- [Authentication & Authorization Security Knowledge Base](https://gitlab.com/gitlab-com/content-sites/internal-handbook/-/blob/main/content/handbook/security/product_security/application_security/authn-authz-security-knowledge.md) (internal)
