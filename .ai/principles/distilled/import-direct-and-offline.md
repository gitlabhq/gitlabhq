---
source_checksum: 5a94df5e53c12bf0
distilled_at_sha: 403f0ba78983ea28f47a927139b91425bb93dcef
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

> **Prerequisite:** If you haven't already, also read .ai/principles/distilled/import-fundamentals.md - it contains foundational rules that apply to all import work.

# Import Direct and Offline Principles

## Checklist

### Architecture and Design

- Use the ETL (Extract/Transform/Load) architecture for all pipelines: declare an extractor, zero or more transformers (run in declaration order), and a loader; DO NOT implement the extract-transform-load loop inside the pipeline class itself.
- Organize pipelines into numbered stages in `lib/bulk_imports/projects/stage.rb` or `lib/bulk_imports/groups/stage.rb`; a stage only starts once every pipeline in the previous stage finishes.
- Place shared pipelines (used by both Group and Project migrations) under `BulkImports::Common::Pipelines`; place project-only pipelines under `BulkImports::Projects::Pipelines` and group-only pipelines under `BulkImports::Groups::Pipelines`.
- Prefer NDJSON relation exports over GraphQL API fetching for ActiveRecord associations; DO NOT use direct GraphQL API queries for heavily-nested associations that would generate excessive network requests.

### Adding a New Relation

- Put newly added relations behind a feature flag to mitigate the risk of introducing bugs and performance issues.
- Add new ActiveRecord associations to `import_export.yml` (project or group variant) under `tree.project` or `tree.group`; add EE-only associations to the `ee.tree.project` tree at the end of the file.
- List associations in `import_export.yml` in dependency order (dependencies before the associations that require them).
- Add `included_attributes` entries for every attribute that must be exported; attributes not listed are filtered out on both export and import.
- Add `excluded_attributes` entries for attributes that must not be exported: anything ending in `_id`/`_ids`, containing `attributes` (except `custom_attributes`), ending in `_html`, or holding sensitive data such as tokens or encrypted values.
- Add `methods` entries for any relation method whose return value must be exported and used on import.
- Specify `minimum_source_version` on a pipeline stage entry when the relation export was introduced in a specific GitLab version; specify `maximum_source_version` when a relation is deprecated and the pipeline should only run up to a certain version.
- Add a new key-value pair to `BULK_IMPORT_STATIC_ITEMS` in `app/assets/javascripts/import/constants.js` for every new relation so it displays in human-readable form in the UI.

### Binary Relations

- For binary relations, create a dedicated export service (see `BulkImports::LfsObjectsExportService` as an example), add the relation to the `file_relations` list in `BulkImports::FileTransfer::ProjectConfig`, and add it to `BulkImports::FileExportService`.
- Use `BulkImports::FileDownloadService`, `BulkImports::FileDecompressionService`, and `BulkImports::ArchiveExtractionService` as helpers in binary-relation pipeline extract steps.

### Custom Association Names and Deduplication

- Add associations whose name does not match their ActiveRecord class name to the `OVERRIDES` hash in `Gitlab::ImportExport::Project::RelationFactory` (or the Group equivalent) so the importer can constantize them correctly.
- Add associations that are referenced by multiple other relations to `EXISTING_OBJECT_RELATIONS` in `RelationFactory` and implement the corresponding `ObjectBuilder` lookup attributes to prevent duplicate records on import.

### Idempotency and Error Handling

- Ensure pipeline jobs are idempotent: each entry is cached as it is processed so that Sidekiq retries do not create duplicate records.
- DO NOT let a single bad record fail the entire pipeline; `BulkImports::Pipeline::Runner` processes NDJSON entries one at a time and records failures as `BulkImports::Failure` without stopping the pipeline (unless the pipeline class is marked `abort_on_failure!`).
- Ensure `RelationObjectSaver` saves the top-level record first so that an invalid nested sub-relation does not fail the parent record; record each invalid sub-relation as its own `BulkImports::Failure`.

### User Contribution Mapping

- Use `BulkImports::Common::Pipelines::MembersPipeline` (via `SourceUserMemberAttributesTransformer` and `Import::SourceUserMapper`) as the primary mechanism for creating source user and placeholder records.
- DO NOT create placeholder users for relations listed in `BulkImports::NdjsonPipeline::IGNORE_PLACEHOLDER_USER_CREATION` (approvals, builds, ci_pipelines, events, and similar) because they may reference users that no longer exist on the source instance.
- Assign contributions from the source ghost user directly to the destination ghost user; DO NOT create a placeholder user for the source ghost user.

### Test Coverage

- Add export-side test coverage for new ActiveRecord relations to `spec/lib/gitlab/import_export/project/tree_saver_spec.rb` (and the EE equivalent for EE-specific relations).
- Add a separate pipeline spec for each new import pipeline, following the structure of existing specs such as `spec/lib/bulk_imports/common/pipelines/milestones_pipeline_spec.rb`.

## Authoritative sources

For the full picture, see:

- doc/development/bulk_import.md
- doc/development/bulk_imports/contributing.md

