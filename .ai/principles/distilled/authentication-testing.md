---
source_checksum: 8160d7d4525f6096
distilled_at_sha: 0bc240cb0e70d2bba500cca6317a5c7e9e06605e
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Authentication Testing Principles

## Checklist

### Token Edge Cases

- Specs for endpoints that accept tokens should cover expired tokens, malformed tokens, revoked tokens, wrong-scope tokens, and (where applicable) replay.
- Reference patterns: `spec/lib/gitlab/auth/auth_finders_spec.rb` and `spec/requests/api/api_guard_spec.rb`.

### Authorization Actor Matrix

- Specs for controllers, API endpoints, or policies with authorization checks should exercise the full actor matrix: authorized user (allowed), unauthorized user (forbidden), anonymous user (redirect or 401), and admin user where the role affects behavior. Do not only test the "everything works" case.

### Admin Mode Activation

- Use the `:enable_admin_mode` RSpec metadata tag to activate admin mode in specs; DO NOT use `enable_admin_mode!(admin, use_ui: true)` — it is slow and introduces a race condition where the mode-activation request may not complete before the next action runs.

### Auth-Stubbing Red Flags

- Flag specs that stub the auth layer in ways that hide regressions:
  - `allow_any_instance_of(...).to receive(:current_user).and_return(...)` to short-circuit auth.
  - `allow(Ability).to receive(:allowed?).and_return(true)` (or `false`) to bypass the policy framework.
  - Stubbing `sign_in` without using the Devise/Warden test helpers.
- Use real users and real policies in auth specs; stub only external dependencies (for example, IAM service HTTP calls).
- Safe to stub (do not flag): external HTTP calls (`IamService` client, OAuth provider callbacks); Sidekiq workers in unrelated specs; time helpers (`travel_to`, `freeze_time`); feature flag state (`stub_feature_flags`); application settings (`stub_application_setting`); file and storage clients (`Fog`, `CarrierWave`, GCS/S3 doubles).

### Rate-Limit Specs

- When a change adds or modifies a rate limit (`check_rate_limit!`, `Gitlab::ApplicationRateLimiter`), verify a spec covers (a) the limit fires after N attempts, and (b) the limit key includes the credential subject, not only the IP.
- Use `spec/support/shared_examples/controllers/rate_limited_endpoint_shared_examples.rb` if a shared example applies.

### Narrow Token Scopes in Specs

- When a spec creates a PAT, OAuth token, or job token, use the narrowest scope sufficient. A spec that uses `:api` scope to test a `:read_user`-protected endpoint can mask a scope-enforcement bug. Prefer `create(:personal_access_token, scopes: [:read_user])` when the endpoint requires only read access.

## Authoritative sources

For the full picture, see:

- doc/development/testing_guide/best_practices.md

