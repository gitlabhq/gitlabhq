---
source_checksum: 3c85628c6d7cae8a
distilled_at_sha: 52964caf288c3d9936b8ce4a3d2242c1f92567fa
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# GraphQL Principles

## Checklist

### Breaking Changes

- DO NOT remove, rename, or change the type of a field, argument, enum value, or mutation without following the deprecation process.
- DO NOT change an argument from optional (`required: false`) to required (`required: true`) without deprecation.
- DO NOT change a field from nullable (`null: true`) to non-nullable (`null: false`) without deprecation.
- DO NOT raise the complexity of a field or complexity multipliers in a resolver without deprecation.
- DO NOT change the max page size of a connection without deprecation.
- Deprecate schema items using the `deprecated:` property with `reason:` and `milestone:` keys; DO NOT remove them directly.
- Maintain the original `description:` on deprecated items; append the reason via the `reason:` key, not by editing the description.
- Use `Use \`otherFieldName\`` as the deprecation reason when a field is replaced by another.
- Deprecation issue created using the `Deprecations` issue template with `~GraphQL` and `~deprecation` labels
- Add deprecated mutations to `Types::DeprecatedMutations` and test them in `Types::MutationType` unit tests.
- Use `mount_aliased_mutation` to alias a mutation when renaming, to preserve the old name during the deprecation period.
- When renaming a model whose Global ID is used as an argument type, add a `Deprecation` entry to `Gitlab::GlobalId::Deprecations::DEPRECATIONS` instead of making a breaking change.
- DO NOT deprecate Global ID fields (only arguments); field Global ID changes are considered backwards-compatible.

### Experiments

- Mark new schema items under a feature flag with `experiment: { milestone: '...' }`.
- DO NOT mark existing (already public) schema items as experiments.
- Remove the `experiment:` property when the feature flag is removed to make the item public.
- Include a changelog entry for all public-facing changes not marked as experiments.

### Multi-version Compatibility

- Ensure frontend and backend code for the same GraphQL feature are NOT shipped in the same release (deploy backend before frontend on GitLab.com).
- Use the `@gl_introduced` directive on fields for Self-Managed/Dedicated to strip future nodes from queries hitting older backend versions.
- DO NOT use `@gl_introduced` on arguments, fragments, or single future fields that are the only selection in a query or object.
- Treat non-nullable fields with `@gl_introduced` as still requiring null-checks on the frontend.

### Descriptions

- Ensure every field and argument has a `description:` value ending with a period (`.`).
- DO NOT start descriptions with `The` or `A`.
- Use `{x} of the {y}` phrasing for field descriptions where possible.
- Use `Types::TimeType` for all `Time`/`DateTime` fields and include the word `timestamp` in the description.
- For boolean fields, start the description with a verb (for example, `Indicates the issue is confidential.`).
- For sort enum descriptions, use `Values for sorting {x}.`
- When a feature flag toggles a field's value or behavior, state the flag name, what it toggles, and the behavior when disabled in the `description:`.
- Use `copy_field_description(Types::SomeType, :field_name)` to keep descriptions in sync between a type field and a mutation argument.
- Use the `see:` property for external documentation references instead of embedding URLs in descriptions.
- Add subscription tier information inline in the description (for example, `Premium and Ultimate only.`) for fields restricted to higher tiers.

### Types and Fields

- Prefer nullable fields (`null: true`) over non-nullable ones; reserve non-nullable for fields that are required, unlikely to become optional, and cheap to compute (for example, `id`).
- Use `Types::GlobalIDType[Model]` (not plain `ID` or database primary key integers) for all Global ID inputs and outputs.
- Convert non-`id`-named fields that expose Global IDs manually using `Gitlab::GlobalId.build` or `#to_global_id`.
- Use `GraphQL::Types::ID` only for full paths; DO NOT use it for database IDs or IIDs.
- Use `Types::TimeType` for all Ruby `Time` and `DateTime` fields and arguments.
- Use `markdown_field` helper for all fields that return rendered Markdown.
- Mark fields that may call Gitaly with `calls_gitaly: true`; annotate resolvers that call Gitaly with `calls_gitaly!`.
- Set `complexity: 0` for trivially cheap fields (for example, `id`, `title`); set higher complexity for expensive fields.
- Add `extension(::Gitlab::Graphql::Limit::FieldCallCount, limit: N)` and update the field `description:` when limiting field call count to prevent N+1 problems of last resort.
- Use `CountableConnectionType` when exact counts matter; use `LimitedCountableConnectionType` when the collection can be very large and exact counts are not critical.
- DO NOT use `GraphQL::Types::JSON` unless the data is truly unstructured; use typed objects or unions instead.
- DO NOT implement "shortcut fields" (for example, `latest_pipeline`); use pagination arguments instead (for example, `pipelines(last: 1)`).
- Ensure enum class names end with `Enum`, `graphql_name` does not contain `Enum`, and all values are uppercase.
- Dynamically define GraphQL enum values from Rails enums using `each_key` to keep them in sync.
- Place `graphql_name` as the first line of a mutation class.
- Name mutations following `{Resource}{Action}` or `{Resource}{Action}{Attribute}`; use `Create`, `Update`/`Set`/`Add`/`Toggle`, and `Delete`/`Remove` verbs.
- Expose permissions using `expose_permissions` with a type inheriting `BasePermissionType`.

### Arguments

- DO NOT use the `loads:` option in argument definitions; accept the Global ID and load the object manually with `authorized_find!`.
- Use `required: :nullable` when an argument must be provided but its value can be `null`.
- Add `validates: { allow_null: false }` for optional arguments where `null` is not a valid value.
- Use `validates mutually_exclusive:` or `validates exactly_one_of:` for mutually exclusive or exactly-one-of argument groups.
- Use enum types for sort arguments following the `{PROPERTY}_{DIRECTION}` format.
- Name full-path arguments `project_path`, `group_path`, or `namespace_path`; use `iid` with a parent path for IID-identified objects; use `Types::GlobalIDType[Model]` for all other object identifiers.
- Ensure all GraphQL mutations that accept file content use Workhorse-assisted uploads.

### Resolvers and Mutations

- Write resolvers as thin declarative wrappers around finders and services; DO NOT put business logic directly in resolvers.
- DO NOT instantiate resolvers or mutations directly in application code; let the framework manage their lifecycle.
- DO NOT use batching in mutations; mutations execute serially and batching adds unnecessary overhead.
- Use `authorized_find!` in resolvers to load and authorize objects; DO NOT raise errors for unauthorized resources — return `null` instead.
- Use `#ready?` for set-up or early-return logic; use validators for argument validation instead of `#ready?`.
- Ensure `BaseResolver.single` derived resolvers have more restrictive arguments than the collection resolver via a `when_single` block.
- Include `LooksAhead` concern and implement `preloads` / `unconditional_includes` to avoid N+1 queries via lookahead.
- Use `before_connection_authorization` to preload data for type authorization checks and avoid N+1s from permission checks.
- Use `BatchModelLoader` for ID-based record lookups; DO NOT implement custom ID batch loaders.
- DO NOT call `batch.sync` or `Lazy.force` in resolver code; use `Lazy.with_value` instead.
- Define a method under `GraphqlTriggers` to trigger subscriptions; DO NOT call `GitlabSchema.subscriptions.trigger` directly in application code.
- Implement `#authorized?` in subscription classes and call `unauthorized!` when authorization fails.
- Return `errors` as an empty array on success and populate it with user-relevant error messages on failure; raise `raise_resource_not_available_error!` for authorization/not-found errors.
- Mutation payload fields must have `null: true`.
- Return the current true state of the resource in update mutation failures (call `#reset` if needed).
- Catch all anticipated errors and convert them to `Gitlab::Graphql::Errors` types; DO NOT let `StandardError` propagate uncaught (it becomes `Internal server error`).
- DO NOT close over instance state in batch loader blocks; pass all needed data through the `for(data)` call.

### Authorization

- Apply `authorize :ability` on types, resolvers, or fields using `DeclarativePolicy` abilities.
- Use `authorizes_object!` when a resolver should authorize against the parent object.
- Use field-level `authorize:` for scalar fields with different access levels or to avoid expensive per-object checks.
- DO NOT use field authorization as a substitute for object-level checks when objects can have independent access controls (for example, confidential issues).
- Use `skip_type_authorization` on a field only when the resolver already authorizes the resolved objects and the permission checks are equivalent, to avoid redundant N+1 authorization calls.
- Load only what the current user is allowed to see using finders first; DO NOT rely solely on authorization to filter records after loading.

### Performance and N+1

- Check for N+1 queries using `development.log`, the performance bar, or request specs with `QueryRecorder`.
- Use `BatchLoader::GraphQL` for batching queries in resolvers; pass all needed data through `for(data)` and DO NOT close over instance state in batch blocks.
- DO NOT sync lazy values early; queue all lazy requests before calling `#sync`.
- Add a request spec asserting no (or limited) N+1 queries for new collection fields.
- Use different users for each request in N+1 `QueryRecorder` tests to avoid false positives from authentication queries.
- DO NOT build queries through association proxies before applying `includes()`; build at the class level to avoid `Arel::Nodes::LeadingJoin` errors.

### Testing

- Use request (integration) specs in `spec/requests/api/graphql` as the primary test vehicle; DO NOT rely on resolver unit specs for behavior testing.
- DO NOT unit test resolvers beyond statically verifying fields, arguments, or `authorize` declarations.
- Use `post_graphql` / `post_graphql_mutation` helpers and `GraphqlHelpers` methods in integration specs.
- Use `graphql_mutation`, `post_graphql_mutation`, and `graphql_mutation_response` helpers for mutation specs.
- Use `a_graphql_entity_for`, `graphql_data_at`, and `graphql_dig_at` helpers to access and match result fields.
- Use `empty_schema` instead of manually constructing a schema in unit tests.
- Use `get_graphql_query_as_string` to test frontend `.graphql` query files.
- Mirror the folder structure of `app/graphql/types` in `spec/requests/api/graphql`.
- Use `batch_sync` or `Gitlab::Graphql::Lazy.force` only in tests when lazy values must be forced; prefer `Schema.execute` in request specs to avoid manual lifecycle management.

## Authoritative sources

For the full picture, see:

- doc/development/api_graphql_styleguide.md
- doc/development/graphql_guide/reviewing.md
- doc/development/graphql_guide/authorization.md
- doc/development/graphql_guide/batchloader.md

