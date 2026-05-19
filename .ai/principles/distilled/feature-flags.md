---
source_checksum: 3072e9456fed2439
distilled_at_sha: 52964caf288c3d9936b8ce4a3d2242c1f92567fa
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Feature Flags Principles

## Checklist

### General Usage

- Set all newly-introduced feature flags to **disabled by default** (`default_enabled: false`).
- Use actors with feature flags (project, group, user, etc.) to enable targeted rollouts and easier debugging.
- DO NOT use feature flags at application load time (e.g., in `config/initializers/*` or at class level).
- DO NOT use feature flags as long-lived settings; use Cascading Settings or Application Settings instead.
- DO NOT use feature flags in external API consumers (IDE extensions, Duo CLI, CI integrations); introduce a dedicated API field or Application Setting instead.
- If a feature flag must be used in an external API consumer, implement fail-open behavior defaulting to enabled after the rollout milestone is finalized.
- DO NOT use a feature flag name that matches a licensed feature name (causes naming collision); add a dedicated flag under a different name and check both explicitly.
- DO NOT use percentage-of-time rollout; use `Feature.current_request` as actor with percentage-of-actors instead.
- Use `group.root_ancestor` as the actor when flag state must be consistent across an entire group hierarchy.
- DO NOT mix different actor types across invocations of `Feature.enabled?` for the same flag unless you are certain it won't cause inconsistent results within a request.
- Use `:instance` as the actor only when a feature is tied to an entire instance and no other actor type applies.
- DO NOT evaluate feature flags inside cycles where one flag's evaluation triggers another; always access values through `Feature.enabled?` and avoid `Feature.get`.
- Assign the `~"feature flag"` label to MRs that introduce, update state of, or remove a feature flag.
- Use the feature flag in the same MR that introduces it to avoid breaking the default branch (`rspec:feature-flags` job).

### Naming

- Use snake_case for feature flag names.
- Use long, descriptive names over short ambiguous ones.
- DO NOT include state/phase suffixes like `_mvc`, `_alpha`, `_beta` in flag names.
- DO NOT use `disable` in flag names; prefer `hide_`, `remove_`, or `disallow_` prefixes instead.

### YAML Definition

- Create every feature flag definition using `bin/feature-flag` (or `bin/feature-flag --ee` for EE-only).
- Include all required YAML fields: `name`, `description`, `type`, `default_enabled`, `introduced_by_url`, `milestone`, `group`.
- DO NOT guess or hard-code the `milestone` value — read it from the `VERSION` file in the repo root and use the `MAJOR.MINOR` portion only (e.g., if `VERSION` contains `19.0.0-pre`, set `milestone: "19.0"`)
- DO NOT define the same feature flag in both FOSS and EE; define it in one location only.
- Set `default_enabled: false` for `gitlab_com_derisk`, `wip`, and `experiment` types (setting it to `true` has no effect or is forbidden for these types).
- Document `beta` and `ops` type flags in the [All feature flags in GitLab](https://docs.gitlab.com/administration/feature_flags/list/) page.
- Create a rollout issue from the Feature Flag Roll Out template for `gitlab_com_derisk` and `beta` flags.
- Optionally add a `.patch` file alongside the YAML to enable automated removal via `gitlab-housekeeper`.

### Type Selection

- Use `gitlab_com_derisk` for short-lived deployment de-risking flags (max 2 months lifespan).
- Use `wip` for hiding incomplete multi-MR features until fully implemented (max 4 months lifespan); transition to `gitlab_com_derisk` or `beta` before enabling.
- Use `beta` when a feature may have scalability concerns or is not yet a complete MVC (max 6 months lifespan).
- Use `ops` for long-lived operational control flags; evaluate every 12 months and update `milestone` to confirm continued use.
- Use `experiment` for A/B testing on GitLab.com (max 6 months lifespan); create rollout issue from the Experiment Rollout template.
- DO NOT use the deprecated `development` type; use `gitlab_com_derisk`, `wip`, or `beta` instead.

### Backend Usage

- Pass an actor as the second argument to `Feature.enabled?` and `Feature.disabled?`.
- Use `Project.actor_from_id(project_id)` instead of `Project.find(project_id)` when the model is only needed for the feature flag check.
- For feature flags without a YAML definition (only `experiment`, `worker`, `undefined` types), pass `type:` explicitly to `Feature.enabled?`, `Feature.disabled?`, and `push_frontend_feature_flag`.

### Frontend Usage

- Use `push_frontend_feature_flag` in a `before_action` scoped to a project or user actor.
- Check feature flag state in JavaScript using camelCase (`gon.features.vimBindings`), not snake_case.
- Ensure a backend feature flag guards the underlying backend code whenever a frontend feature flag is used.

### Changelog

- DO NOT add a changelog entry for changes behind a feature flag that is disabled by default.
- Add a changelog entry for changes behind a feature flag that is enabled by default.
- Add a changelog entry when changing the feature flag itself (removal or flipping to default-on).
- Describe the feature in the changelog entry, not the flag itself (except when a default-on flag is removed keeping new code, use `other` type).
- Always include a changelog entry for database migrations regardless of feature flag state.

### Tests

- DO NOT stub feature flags to `true` — they are enabled by default in the test environment.
- Use `stub_feature_flags(flag_name: false)` to test the disabled state; place the stub in a `before` hook within a self-contained context.
- Include automated tests for both enabled and disabled states of every feature flag.
- Prefer `stub_feature_flags` over `Feature.enable*` for test setup; use `Feature.enable_percentage_of_time` or `Feature.enable_percentage_of_actors` only when testing percentage rollout behavior.
- Use `have_pushed_frontend_feature_flags` matcher to verify `push_frontend_feature_flag` added the flag to HTML.
- Use `stub_feature_flag_gate` to create a custom actor for actor-specific flag testing in specs.
- DO NOT use `stub_feature_flags: false` unless specifically testing Flipper's interaction with `ActiveRecord`.
- Be aware that end-to-end (QA) tests do NOT enable feature flags by default; use the API-based process for toggling flags in E2E tests.

### Experiments

- If experiment uses only `experiment(:name, actor: current_user)` as context but the corresponding issue mentions tracking of namespace-based activation events, assignment should happen based on namespace or actor + namespace
- If experiment is first assigned during registration, there should be another assignment tracking event with namespace context: `experiment(:name, actor: current_user).track(:assignment, namespace: group)`

### Sidekiq Worker Flags

- Use `run_sidekiq_jobs_{WorkerName}` (worker-type flag) to defer Sidekiq jobs during incidents; remove the flag after the worker is deemed safe.
- Use `drop_sidekiq_jobs_{WorkerName}` only when jobs are certain to not need future processing; note it takes precedence over `run_sidekiq_jobs_{WorkerName}`.

### Migration to Application Settings

- Ensure backfill migration and code changes using the new application setting are merged in the same milestone when migrating an `ops` flag to an application setting.
- Match the application setting default to `default_enabled:` from the feature flag YAML definition.
- Use `Gitlab::Database::MigrationHelpers::FeatureFlagMigratorHelpers` helpers in the migration; DO NOT use `Feature.enabled?` or `Feature.disabled?` inside migrations.

## Authoritative sources

For the full picture, see:

- doc/development/feature_flags/_index.md

