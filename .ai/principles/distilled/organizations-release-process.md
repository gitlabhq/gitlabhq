---
source_checksum: 6baee32fe4bf54f6
distilled_at_sha: 586530a94f045df52e8ae3e37a72e449e7dd1e43
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

> **Prerequisite:** If you haven't already, also read .ai/principles/distilled/organizations-fundamentals.md - it contains foundational rules that apply to all organizations work.

# Organizations Release Process Principles

## Checklist

### Gating Features

- Use `Organizations::Release.enabled?(:flag_name, actor)` to gate organization features; DO NOT check a feature flag directly.
- Preserve access as a feature advances: check Experimental for later stages and Beta for LA stages; DO NOT cascade LA percentage buckets into one another.
- Pass a consistent actor type at every call site for a given organization flag, because shared stage flags bucket by actor type for percentage rollouts.
- Pass `nil` as the actor only to check instance-wide (boolean) gates; DO NOT pass `nil` when a percentage-of-actors gate must match.
- Configure each LA stage flag with a percentage-of-actors gate matching the percentage in its name, not a percentage-of-time gate, so each actor remains consistently included or excluded.
- Use `push_frontend_organization_release(:flag_name, actor)` to expose an organization flag to the frontend; DO NOT push the backing stage flag directly.

### Registering Organization Flags

- Declare every organization flag in `config/organizations_release.yml` with a `name`, `description`, and `stage`.
- Set `stage` to one of `experimental`, `beta`, `la_25`, `la_50`, `la_75`, `la_100`, or `ga`; start new flags at `experimental` unless a later stage is appropriate.
- DO NOT create a custom feature flag or tune actors/percentages for an individual organization flag; advance the feature by raising its `stage` in `config/organizations_release.yml`.

### Testing

- Use `stub_organization_release(:flag_name, enabled: true/false)` to toggle an organization flag in specs; DO NOT stub the backing stage flag directly.
- DO NOT stub organization flags to `true` — they are enabled by default in the test environment; use `enabled: false` to disable.

### Advancing Through Stages

- Advance a feature one stage at a time via a merge request that raises the `stage` value in `config/organizations_release.yml`.
- DO NOT skip Beta; DO NOT skip LA 100 before GA. Experimental and intermediate LA increments (LA 25, LA 50, LA 75) are optional.
- Ship `org_stage_ga` as `default_enabled: true` when reaching GA; this carries the feature to GitLab Self-Managed and GitLab Dedicated.
- Reach Stable by removing the organization flag's `config/organizations_release.yml` entry and replacing all `Organizations::Release.enabled?` call sites with unconditional behavior; DO NOT set `stage: stable`.
- To roll back a feature, lower the organization flag's `stage` in the same way it was raised.
- Use independent feature flags (not the shared stage flags) only for high-risk features that require their own rollout control.

### Release Status Documentation

- Regenerate `doc/development/organizations/release_status.md` after every stage change by running `bin/rake gitlab:organizations:release:docs`; DO NOT edit that file by hand.

### Organization Creation Paths

- Verify each organization-creation path against its current server-side gates: the form uses `org_creation` and `:create_organization`, GraphQL uses `organization_switching` and `:create_organization`, and REST uses `org_creation`, `:create_organization`, and a rate limit; DO NOT treat navigation or UI visibility as enforcement.
- Ensure the REST API path (`POST /organizations`) also enforces a rate limit in addition to the flag and ability checks.
- Gate the top-level group backfill and confirm path behind ChatOps-triggered ops feature flags (`root_group_organization_backfill`, `root_group_organization_confirm`); note that both workers use `skip_authorization: true` and bypass all other gates.
- Gate the "Create organization from group settings" self-serve path behind the `create_org_from_group_settings` organization flag (group actor), the `:create_organization` ability, and the `:admin_group` ability.
- Verify that the current `:create_organization` ability requires both GitLab.com and the `can_create_organization` application setting; it is prevented on every other instance.

## Authoritative sources

For the full picture, see:

- doc/development/organizations/release_process.md
- doc/development/organizations/organization_creation.md

