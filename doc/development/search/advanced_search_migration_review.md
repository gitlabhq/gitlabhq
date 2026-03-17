---
stage: AI-powered
group: Global Search
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Advanced Search Migration Review Guidelines
---

This page is specific to advanced search migration reviews. Refer to our
[code review guide](../code_review.md) for broader advice and best
practices for code review in general.

## When a review is needed

An advanced search migration review is required for:

- Changes to files in `ee/elastic/migrate/`
- Changes to index mappings or settings
- Changes to document serialization in `Search::Elastic::References::<IndexedData>` or
  legacy `Elastic::Latest::<IndexedData>InstanceProxy` classes
- Changes that affect indexing behavior or data consistency

## Roles

Authors must provide the [required artifacts](#required-artifacts) before requesting review.
Reviewers ensure artifacts are complete and perform a first-pass review. Maintainers perform the
final review and merge when approved.

## Required artifacts

You must provide the following when requesting a review. If your merge request description does
not include these items, the review is reassigned back to the author.

### All migrations

- **Migration purpose**: What the migration does and why it's needed.
- **Affected document type**: Which index and document type is modified (for example,
  `WorkItem`, `MergeRequest`, `Commit`).
- **Backwards compatibility**: How the migration handles multi-version compatibility.
- **Testing**: Run the migration locally and confirm `completed?` returns true after execution. For
  batched migrations, verify batching works as expected.

### Mapping or settings changes

- **Before and after**: Show exact changes to index configuration.
- **Impact analysis**: How the change affects existing documents, search behavior, and performance.

### Backfill or reindex migrations

- **Data volume estimate**: Approximate number of documents affected.
- **Runtime estimate**: Expected execution time on GitLab.com using
  the [calculation formula](advanced_search_migration_styleguide.md#calculating-migration-runtime).
- **Batch size justification**: Why the chosen batch size and throttle delay are appropriate.
- **Query plan** (if applicable): The Elasticsearch query being executed.

### Data modification migrations

- **Reversibility**: Confirm the migration is reversible or explain why it cannot be.
- **Data safety**: Safeguards against data loss or corruption.
- **Validation**: How to verify the migration completed successfully.

## Review checklist

### Basics

- Migration follows the [style guide](advanced_search_migration_styleguide.md) format.
- Merge request has a changelog.
- Appropriate [migration helpers](advanced_search_migration_styleguide.md#migration-helpers) are
  used.
- Spec file exists with adequate test coverage
  using [shared examples](advanced_search_migration_styleguide.md#spec-support-helpers).
- YAML documentation file exists in `ee/elastic/docs/` with required fields:
  - `description` - what the migration does
  - `introduced_by_url` - link to the merge request that introduced the migration
  - For skippable migrations: `skippable: true` and `skip_condition`
  - For obsolete migrations: `marked_obsolete_by_url` and `marked_obsolete_in_milestone`

### Backwards compatibility

- Migration handles the case where pre-migration application code is still running. See [multi-version compatibility](advanced_search_migration_styleguide.md#multi-version-compatibility).
- Destructive operations (deletions, field removals) are deferred to a later release if needed.
- `schema_version` is [incremented appropriately](../advanced_search.md#create-the-index) for
  document changes. The format is `YYVV` (two-digit year and rolling version counter within that
  year, for example `24_46`).
- Code that depends on the migration uses `Elastic::DataMigrationService.migration_has_finished?`
  to check if the migration is complete before using new fields or behavior.

### Data safety

- Migration doesn't introduce orphaned or inconsistent data.
- For document modifications: `as_indexed_json` method is updated to match.
- Authorization fields (`visibility_level`, `traversal_ids`, etc.) are handled correctly.
- Migration doesn't conflict with ongoing indexing from `Elastic::ProcessBookkeepingService`.
- Custom Elasticsearch queries are reviewed for correctness.

### Performance

- Runtime estimate is reasonable using the [calculation formula](advanced_search_migration_styleguide.md#calculating-migration-runtime).
- Batch size is not greater than `10_000` documents.
- Throttle delay is appropriate for batch size and operation complexity.
- Large migrations use `batched!` with appropriate delays.
- For migrations: `preload_indexing_data` method efficiently loads associated data before indexing.
- For search results: Model includes `preload_search_data` scope to preload associations when returning results.

### Index mappings

- Mapping changes are applied to `Search::Elastic::Types::<IndexedData>` or legacy
  `Elastic::Latest::<IndexedData>Config`.
- New fields have appropriate types and analyzers.
- Follow-up backfill migration is included if needed.
