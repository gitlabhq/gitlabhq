---
source_checksum: 259347344c386550
distilled_at_sha: f61a71870e300699d0cbf5f4ba05fb6666928907
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

> **Prerequisite:** If you haven't already, also read .ai/principles/distilled/cells-fundamentals.md - it contains foundational rules that apply to all cells work.

# Cells Claims Principles

## Checklist

### Attribute Selection

- Claim attributes that are used for routing (URL, REST API, GraphQL API) or for logging in, as these must be globally unique across the cluster.
- Ensure every `cells_claims_attribute` specifies both a `type` (bucket type) and a `feature_flag` (model-specific control flag).
- Define `cells_claims_metadata` with `subject_type` and `subject_key` on every claimable model; `source_type` and source value are inferred automatically.

### Adding a New Claimable Model

- Include `Cells::Claimable` in the model before declaring any `cells_claims_attribute` or `cells_claims_metadata`.
- Create a `beta` feature flag YAML file at `config/feature_flags/beta/cells_claims_<model>s.yml` with `default_enabled: false` and `group: group::cells infrastructure`.
- Create a separate `beta` feature flag YAML file at `config/feature_flags/beta/cells_claims_verification_worker_<model_name>.yml` with `default_enabled: false`.
- Add new `Bucket::Type`, `Subject::Type`, and `Source::Type` entries in Topology Service's `proto/claims/v1/messages.proto` before using them in Rails.
- Add validation rules for the new bucket type in Topology Service's `validation.go` to prevent incorrect usage.
- After the Topology Service MR is merged, update the Topology Service client in GitLab by running `scripts/update-topology-service-gem.sh` in the MR branch.
- Audit the model for ActiveRecord-bypassing code paths (`delete_all`, `insert_all`, `upsert_all`, raw SQL) and handle claims for those paths using `Cells::BulkClaimsWorker`.
- Add model tests using `it_behaves_like 'cells claimable model'` and a dedicated spec file in `spec/cells/claims/<model>_spec.rb` covering creating, deleting, and updating claims.

### Feature Flags

- Enable both the global flag (`cells_unique_claims`) and the model-specific flag (`cells_claims_<model>s`) for claims to take effect; claims do not work if either flag is disabled.
- Enable the verification worker flag (`cells_claims_verification_worker_<model_name>`) only after the model-specific claiming flag is already active.
- Use the parameterized model name (for example, `user`, `email`, `route`) as `<model_name>` in verification worker feature flag names.
- Test feature flag behavior with `stub_feature_flags(cells_claims_your_model: false)` and assert that no claims are created or deleted when the flag is disabled.

### Rollout Lifecycle

- Follow the two-phase rollout: Phase 1 enables live request claiming via `Cells::Claimable` callbacks; Phase 2 enables the verification worker for backfilling and ongoing consistency.
- Ensure the feature-owning team (not the Cells Infrastructure team) owns the rollout of both phases, including creating flags, enabling them, and monitoring correctness.

### Conditional Claiming (`if:` and `cells_claims_scope`)

- Use the `if:` lambda option on `cells_claims_attribute` to skip claiming specific values (for example, sub-paths or `nil` values); the lambda receives the record and must return a boolean.
- Use `cells_claims_scope` with a block returning an `ActiveRecord::Relation` to exclude rows from verification at the database level; define a block only when database-level exclusion is needed.
- Use `if:` and `cells_claims_scope` together when per-record save-time filtering and verification-time query filtering are both needed; use `if:` alone when only instance-level filtering (for example, skipping `nil`) is required.
- DO NOT rely on `if:` alone to exclude rows from verification scans when a database-level filter is also needed — define `cells_claims_scope` in that case.

### Bulk Claiming for ActiveRecord-Bypassing Code Paths

- Use `Cells::BulkClaimsWorker` for code paths that use `delete_all`, `insert_all`, `upsert_all`, or raw SQL, because `Cells::Claimable` callbacks are bypassed in those paths.
- Build `destroy_metadata` with `build_destroy_metadata_for_worker` before deleting records, because metadata must be captured while the record still exists.
- Pass `create_record_ids` (array of IDs) to `Cells::BulkClaimsWorker` for inserts; the worker loads records and builds claim metadata from them.
- Schedule `Cells::BulkClaimsWorker` with `run_after_commit` to keep claim operations outside the database transaction.
- Batch worker calls using `Cells::Claimable::BULK_CLAIMS_BATCH_SIZE` when scheduling bulk claim jobs.
- Check `cells_claims_enabled_for_attribute?` before scheduling `Cells::BulkClaimsWorker`.

### Verification and Backfilling

- Rely on `Cells::Claims::VerificationService` (triggered by `cells_claims_verification_worker_<model_name>`) for backfilling existing records and for ongoing drift correction — DO NOT attempt manual backfills.
- Expect the verification worker to skip records updated within the last hour to avoid conflicts with in-flight saves.
- Expect the verification worker to persist progress (last processed ID) to Redis and reschedule itself if it runs out of time (4.5-minute limit), so DO NOT assume a single run processes all records.

### Tests

- Add `it_behaves_like 'cells claimable model'` to the model spec, specifying `subject_type`, `subject_key`, `source_type`, and `claiming_attributes`.
- Add a dedicated spec file at `spec/cells/claims/<model>_spec.rb` using the shared examples `'creating new claims'`, `'deleting existing claims'`, and `'updating existing claims'`.
- Override `claims_records` in the shared context when associated models also have claimable attributes (for example, `User` and its `Email` association).
- Define `transform_attributes` for the `'updating existing claims'` shared example to specify which attributes change and verify old claims are destroyed and new ones are created.
- Omit the `'updating existing claims'` shared example only when the record can never be updated.

### Validation in GDK

- Validate claims locally by running `gdk psql -d topology_service -c "SELECT * FROM claims;"` after creating, updating, or deleting records.
- Ensure both the `cells` GDK setup and the `cells_unique_claims` feature flag are enabled before attempting local validation.

## Authoritative sources

For the full picture, see:

- doc/development/cells/claims.md

