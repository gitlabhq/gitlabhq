---
source_checksum: aff32136b0f97801
distilled_at_sha: 3941b843c30927ec6cea3e9caa43c88e5f930cb6
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
- Place CI YAML parsing changes behind a feature flag that is default-enabled for a full milestone before removal, so Self-Managed and Dedicated users can revert to the original behaviour if unexpected side effects arise.

### Testing and Validation

- Add or update the corresponding spec file whenever an entry is added or modified.
- Add or update integration tests in `spec/lib/gitlab/ci/yaml_processor_spec.rb` or the files under `spec/lib/gitlab/ci/yaml_processor/test_cases/` for every new or changed keyword.

### YAML Keyword Reviews

- For path-based keywords: document and test whether glob patterns (`*`, `**`, `?`), relative/absolute paths, symbolic links, and missing-path behaviour are supported; explicitly document and spec any intentionally unsupported behaviour so a future accidental enablement causes a test failure.
- For variable expansion: document the expansion type in the [variables usage table](https://docs.gitlab.com/ci/variables/where_variables_can_be_used/#variables-usage), test both positive and negative cases, and add a spec that prevents accidental future enablement of unsupported nested expansion (which would be a breaking change).
- For keyword reuse (adding an existing keyword as a subkeyword): document any unsupported sub-features, provide clear validation errors for unsupported syntax, and test scenarios where users assume the subkeyword behaves identically to the original.
- For composability: document and test `!reference` tag behaviour (a frequent source of unexpected behaviour), `include:` semantics, and `extends:` merge behaviour (deep-merges hashes but replaces arrays); add validation that rejects unwanted `!reference` or `include:` usage where applicable.
- Ensure every relevant usage dimension (string length, list/array size) has a documented limit with a note on the performance impact of raising it; DO NOT ship a keyword without limits on every dimension that could be exploited at scale.
- Ensure all implemented behaviour is documented, all documented behaviour is covered by specs, validation errors are specific and actionable, and JSON schema validation is consistent with backend validation; update the syntax reference page with the new or changed keyword and include examples covering common use cases with limitations and gotchas clearly called out.

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
- doc/development/cicd/keyword_reviews.md

