---
source_checksum: 84eba7174fc3af23
distilled_at_sha: da75f7373628b035becb13fb3f0d21b4b3d3690f
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Import Fundamentals Principles

## Checklist

### Security

- Validate all uploaded files before processing (see `BulkImports::FileDownloadService` and `ImportExport::CommandLineUtil` for examples).
- DO NOT add third-party Ruby gems that make HTTP calls to importers; follow the same Ruby gem policy as integrations.
- Use `Import::Clients::HTTP` for all HTTP calls to enforce network settings, DNS-rebinding protection, and response size validation.
- Add new Import/Export relations behind a feature flag to mitigate the risk of bugs and performance issues.
- Add new exported attributes to `SAFE_MODEL_ATTRIBUTES` or denylist them in `IMPORT_EXPORT_CONFIG` (`excluded_attributes` section) when `AttributeConfigurationSpec` flags them.
- Add new exported models to `import_export.yml` and to `ce_models_yml` when `ModelConfigurationSpec` flags them.
- Add sensitive or encrypted columns to `IMPORT_EXPORT_CONFIG` exclusions or to `RelationFactory::TOKEN_RESET_MODELS` (for generated unique tokens) when `ExportFileSpec` flags them.

### Versioning

- Bump the Import/Export version only for breaking changes (renaming models/columns or changing JSON/archive file structure); DO NOT bump for adding/removing columns or models or exporting new things.
- Run `bundle exec rake gitlab:import_export:bump_version` to fix integration specs after every version bump.

### Logging

- Include the importer type (e.g. `github`, `bitbucket`, `bitbucket_server`) in every log entry.
- Include object identifiers (`id`, `iid`, object type) and error/status messages in log entries to aid debugging.
- DO NOT include sensitive or private information (usernames, email addresses) in logs.
- Track errors in `Gitlab::Import::ImportFailureService` where applicable to surface them in the UI.
- Raise an error in development when key log identifiers are missing.
- Emit a log line before and after each record is imported, containing that record's identifier.

### Performance

- Use a cache with a default TTL of 24 hours to prevent duplicate database queries and API calls.
- Equip workers that loop over collections with a progress pointer so they can resume after interruption (by ID tracking or page counter).
- Implement `defer_on_database_health_signal` on write-heavy workers to avoid saturating the database (note: a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/429871#note_1738917399) currently prevents its use).
- Enforce limits on worker concurrency to avoid saturating resources (see the Bitbucket `ParallelScheduling` class for an example).
- Test importers at scale on a staging environment, especially when implementing new functionality or enabling a feature flag.

### Resilience

- Ensure workers are idempotent so they can be retried safely on failure.
- Re-enqueue workers with a delay that respects concurrent batch limits.
- Keep individual workers short-running; if a worker must run long, refresh its JID using `Gitlab::Import::RefreshImportJidWorker` and raise `max_retries_after_interruption` as needed to avoid termination by `StuckProjectImportJobsWorker`.
- Annotate long-running workers with `worker_resource_boundary :memory` to place them on a shard with a two-hour termination grace period.
- Implement fall-back mechanisms in workers that rely on cached values: re-fetch data on cache miss where possible, and gracefully handle missing values.
- DO NOT fail an entire import when a single record fails; log the error and decide whether to retry based on the nature of the error.
- Set `retries: 6` on Import Stage workers (including `StageMethods`) and Advance Stage workers (including `Gitlab::Import::AdvanceStage`) for resilience to system interruptions.
- Design imports so that a portion can be retried (e.g. re-importing missing issues) without overwriting the entire destination project.

### Consistency

- Fire callbacks after saving imported records; disable problematic callbacks individually by including the `Importable` module, configuring the callback to skip when `importing?`, and setting the `importing` value on the object.
- Manually run callbacks when records must be inserted in bulk.

### Test Fixtures

- Store Import/Export spec fixtures in `spec/fixtures/lib/gitlab/import_export` (both Project and Group fixtures).
- When updating fixtures, update both the human-readable JSON file (`project.json` or `group.json`) and the `tree` NDJSON folder; DO NOT edit files under `tree` manually unless strictly necessary.
- Generate the Project NDJSON tree using `legacy-project-json-to-ndjson.sh` and the Group NDJSON tree using `legacy-group-json-to-ndjson.rb` (tools from `gitlab-org/cloud-connector-team/team-tools`).

## Authoritative sources

For the full picture, see:

- doc/development/import/principles_of_importer_design.md
- doc/development/import_export.md

