---
source_checksum: 16f13ec3375e15ef
distilled_at_sha: 52964caf288c3d9936b8ce4a3d2242c1f92567fa
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

> **Prerequisite:** If you haven't already, also read .ai/principles/distilled/backend-ruby.md - it contains foundational rules that apply to all backend work.

# EE Features Principles

## Checklist

### File Placement and Structure

- Place all EE-only code in the `ee/` top-level directory; keep CE files as close to unmodified as possible.
- Place EE-only classes (no CE counterpart) directly in `ee/` without an `EE` namespace (e.g., `ee/app/models/awesome.rb` with class `Awesome`).
- Place EE extensions of CE classes in `ee/` with the `EE` namespace (e.g., `ee/app/models/ee/user.rb` with module `EE::User`).
- Place EE-only specs in `ee/spec/` without a second `ee/` subdirectory (e.g., `ee/spec/models/vulnerability_spec.rb`).
- Place EE extension specs in `ee/spec/` including the second `ee/` subdirectory (e.g., `ee/spec/models/ee/user_spec.rb`).
- Place EE-specific GraphQL mutations, resolvers, and types in `ee/app/graphql/ee/{mutations,resolvers,types}`.
- Place EE-specific background migration stubs in CE (`lib/`) with no implementation, and extend them in `ee/lib/ee/`.
- Place EE-only frontend files in `ee/app/assets/javascripts/`; use the `ee_else_ce` import alias for files that differ between CE and EE.
- Place EE-only initializer code in `ee/config/initializers`; use `Gitlab.ee { ... }` in `config/initializers` only when splitting is not possible.
- Place EE-only routes using `Gitlab.ee { draw :ee_only }`; use `draw_all` only when both CE and EE route files exist.
- Place all Dedicated-specific code in the `ee/` directory structure.

### EE Module Injection Pattern

- Use `prepend_mod`, `extend_mod`, or `include_mod` (not `prepend`, `extend`, or `include`) to inject EE modules into CE classes.
- Use `prepend_mod_with`, `extend_mod_with`, or `include_mod_with` when the EE module does not follow the default naming convention.
- Always call `prepend_mod` (or variants) on the last line of the CE file where the class resides.
- Use `extend ::Gitlab::Utils::Override` and the `override` guard in every EE module that overrides a CE method.
- Wrap EE extension modules in `module EE` to avoid naming conflicts.
- Use `ActiveSupport::Concern` with `extend ::Gitlab::Utils::Override` inside `class_methods` when overriding CE class methods.
- DO NOT override CE methods that contain guard clauses directly; instead refactor the CE method to extract behavior into a separate hookable method, then override that.

### Feature Guarding

- Guard project-scoped EE features with `project.licensed_feature_available?(:my_feature_name)`.
- Guard group/namespace-scoped EE features with `group.licensed_feature_available?(:my_feature_name)`.
- Guard global (instance-wide) EE features with `License.feature_available?(:my_feature_name)`.
- Add new EE licensed features to `PREMIUM_FEATURES` or `ULTIMATE_FEATURES` in `ee/app/models/gitlab_subscriptions/features.rb` based on the required plan.
- Add global (instance-wide) EE features to `GLOBAL_FEATURES` in `ee/app/models/gitlab_subscriptions/features.rb`.
- Guard SaaS-only features with `Gitlab::Saas.feature_available?(:feature_name)`; DO NOT use `Gitlab.com?` for new SaaS-only features.
- Guard Dedicated-only features with `Gitlab::Dedicated.feature_available?(:feature_name)`; DO NOT use `Gitlab::CurrentSettings.gitlab_dedicated_instance?` directly in application code (migrations are an exception).
- DO NOT use `Gitlab::Saas.feature_available?` in CE code.
- Use `push_licensed_feature` in EE controllers to expose licensed features to the frontend via `gon.licensed_features`.

### SaaS and Dedicated Feature Definitions

- Add new SaaS features to `FEATURES` in `ee/lib/gitlab/saas.rb` and create a YAML definition in `ee/config/saas_features/` using `bin/saas-feature.rb`.
- Add new Dedicated features to `FEATURES` in `ee/lib/gitlab/dedicated.rb` and create a YAML definition in `ee/config/dedicated_features/`.
- Ensure every SaaS and Dedicated feature YAML definition includes at minimum the `name` field and has an owner (`group`).

### Testing EE Features

- Use `stub_licensed_features(my_feature: true)` to enable licensed features in specs; DO NOT rely on implicit license state.
- Use SaaS feature metadata tags (e.g., `:saas_my_feature_name`) on describe/context/it blocks instead of manually calling `stub_saas_features` in `before` blocks where possible.
- Use `stub_saas_features(feature: true/false)` directly only for complex scenarios requiring granular control over enabled/disabled states within the same test.
- Use the `:saas` metadata helper only for code that still relies on `Gitlab.com?` (e.g., database migrations); DO NOT use it for new SaaS-only features.
- Include tests for both the feature-enabled and feature-disabled code paths for every SaaS-only feature.
- DO NOT add EE-only feature examples to existing CE spec files; place them in `ee/spec/`.
- Use `FactoryBot.modify` to extend CE factories in EE; DO NOT define new factories inside a `FactoryBot.modify` block.
- In `RSpec.describe` for EE extension specs, reference the CE class name (e.g., `RSpec.describe User`), not the EE module.
- Add EE-only frontend tests to `ee/spec/frontend/` mirroring the CE directory structure.
- Import modules using `ee_else_ce/...` in frontend specs when the component under test imports them with `ee_else_ce/...`.
- Use `toMatchObject` instead of `toEqual` in CE frontend spec `expect` blocks when comparing objects that may have additional EE-only fields.

### Views and Partials

- Move EE-specific view code into partials; DO NOT embed large EE-specific HAML blocks directly in CE views.
- Use `render_if_exists` instead of `render` in CE views to include EE-only partials.
- Ensure `render_if_exists` partial paths are relative to `app/views/` or `ee/app/views/` (not relative to the calling view's directory).
- Use `render_ce` inside EE partials to explicitly render the CE version of a partial and avoid infinite recursion.

### Frontend EE Patterns

- Use the `ee_component` import alias to import EE components into CE components; DO NOT import directly from `ee/` paths in CE code.
- Use named/scoped slots as the preferred pattern for EE-extended Vue components instead of mixins.
- DO NOT use Vue mixins unless absolutely necessary; prefer slots, scoped slots, or component composition.
- Check `glFeatures.myFeatureName` (from `gon.licensed_features`) in EE Vue components to guard rendering behind a license check.
- Use `ee_else_ce_jest` alias when importing mock data in frontend specs that must work in both CE and EE environments.

### Controllers and Parameters

- Extract `before_action` action lists and `params.permit` attribute lists into separate methods so EE can extend them via `super` without merge conflicts.
- Define empty EE parameter blocks (e.g., `params :optional_project_params_ee do; end`) in CE Grape helpers so EE can override them cleanly.

### Models and Enums

- Define all ActiveRecord `enum` key/value pairs in FOSS (CE) code; DO NOT define enums exclusively in EE.

### SCSS

- Place EE-specific SCSS rules in a separate block clearly delimited with `// EE-specific start` / `// EE-specific end` comments; DO NOT nest EE-specific rules inside CE selectors using `.ee-` class qualifiers on the parent.

### CI and Pipeline

- Add the `~"pipeline:run-as-if-foss"` label to MRs that contain features differing between FOSS and EE to run pipelines in both contexts.

## Authoritative sources

For the full picture, see:

- doc/development/ee_features.md

