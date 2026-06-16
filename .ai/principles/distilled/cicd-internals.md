---
source_checksum: 4186dc0d16bee6b6
distilled_at_sha: f61a71870e300699d0cbf5f4ba05fb6666928907
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# CI/CD Internals Principles

## Checklist

### CI/CD Configuration Keywords

- Add new CI/CD configuration keywords in `lib/gitlab/ci/config/entry/`; for EE-specific changes, use `ee/lib/gitlab/ci/config/entry/` or `ee/lib/ee/gitlab/ci/config/entry/`.
- Guard every experimental CI keyword behind a feature flag; DO NOT add experimental keywords to the JSON schema (to prevent auto-suggestion to users).
- Update the JSON schema (`schema.md`) whenever a new keyword is added or modified.
- Inherit entry classes from the correct base: `Entry::Node` for simple keywords, `Entry::Simplifiable` for keywords with multiple structures, `Entry::ComposableArray` for lists of single-type sub-elements, and `Entry::ComposableHash` for single-type sub-elements with user-defined keys.
- Use `Entry::Validatable` to enable the `validations` block, `Entry::Attributable` to expose `xxx`/`has_xxx?`/`has_xxx_value?` helpers, and `Entry::Configurable` to expose `xxx_defined?`/`xxx_entry`/`xxx_value` helpers.
- Always use the `xxx_value` method (not direct attribute access) to retrieve the value of a nested entry inside the `value` method.
- Override the `value` method only when the default `Entry::Node` behaviour (returning the hash configuration) is insufficient; use `xxx_value` for nested entries and plain attribute accessors for simple attributes.

### Feature Flags in Entry Classes

- Check feature flags inside `Entry::Node#value` (or a private helper) using `Gitlab::Ci::Config::FeatureFlags.enabled?(:flag, type: :beta)` rather than scattering flag checks across callers.
- DO NOT use feature flags in entry classes without an actor; prefer `Feature.enabled?(:flag, Feature.current_request)` or `Config::FeatureFlags.enabled?(:flag)`, or move the flag check outside the entry class entirely.

### Testing and Validation

- Add or update the corresponding spec file whenever an entry is added or modified.
- Add or update integration tests in `spec/lib/gitlab/ci/yaml_processor_spec.rb` or the files under `spec/lib/gitlab/ci/yaml_processor/test_cases/` for every new or changed keyword.

### CI Database Tables (Partitioning)

- Partition every new CI table that holds a `belongs_to` association to a partitionable table from the start, to reduce future migration work.
- Prefix routing table names with `p_` (e.g., `p_ci_examples`); DO NOT use the `p_` prefix for partition names.
- Include a `partition_id` column in every new CI routing table; its value must equal the `partition_id` of the related association (e.g., `p_ci_builds`).
- Order the composite primary key as `[:id, :partition_id]` to allow efficient lookup by `id` alone.
- Add the foreign key with `ON UPDATE CASCADE` using `add_concurrent_partitioned_foreign_key` so that `partition_id` can be updated during partition re-balancing.
- Create the first partition explicitly in a migration (using `with_lock_retries` and explicit `LOCK TABLE` statements) rather than relying on the application boot-time initializer, to prevent node startup failures under high traffic.
- Create partitions in the `gitlab_partitions_dynamic` schema; use `100` as the starting value for `partition_id`.
- Include `Ci::Partitionable` in the model, set `self.table_name` to the routing table, set `self.primary_key = :id`, and declare `partitionable scope: :<association>, partitioned: true`.
- Add every new partitionable model to the `PARTITIONABLE_MODELS` list in `app/models/concerns/ci/partitionable.rb` and register it in the `config/initializers/postgres_partitioning.rb` initializer.

## Authoritative sources

For the full picture, see:

- doc/development/cicd/configuration.md
- doc/development/cicd/cicd_tables.md

