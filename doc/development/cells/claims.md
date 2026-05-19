---
stage: Runtime
group: Cells Infrastructure
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Claiming an attribute for a cell
---

> [!flag]
> Both [cells](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/cells.md#setting-up-cells-locally)
> and feature flag `Feature.enabled?(:cells_unique_claims)` have to be enabled
> for this to take effect.
>
> Additionally, individual model claiming is controlled by model-specific feature flags.
> See [Feature flags](#feature-flags) for the complete list.

## Why we need to claim attributes

Some attributes must be globally unique across the entire cluster. For
example, for routing purposes, we need to ensure that a particular URL or
identifier belongs to at most one cell so we can route to it.

Each cell has its own database, and we cannot enforce unique constraints
across different databases. Therefore, we need a cluster-wide database to
ensure these attributes are unique.

For these attributes, we talk to the Topology Service to claim that an
attribute belongs to a particular cell. Once claimed, no other cell can
claim the same attribute.

## What attributes to claim

Consider whether the attribute is:

- Used for routing?
  - Used in the URL?
  - Used in REST API?
  - Used in GraphQL API?
- Used for logging in?

## Rollout lifecycle

Claiming a new attribute requires two phases. Each phase has its own
feature flag and serves a distinct purpose.

### Phase 1: Live request claiming

Add the `Cells::Claimable` concern to the model and create a
model-specific feature flag. When enabled, Rails `after_save` and
`before_destroy` callbacks claim and release attributes in Topology
Service for every create, update, and delete.

This phase only covers new writes. Existing records in the database are
not claimed until phase 2.

For details on how to configure the model, see
[How to claim attributes](#how-to-claim-attributes).

> [!note]
> The `Cells::Claimable` concern relies on ActiveRecord callbacks. Code
> paths that use `delete_all`, `insert_all`, `upsert_all`, or raw SQL
> bypass these callbacks. For these code paths, use
> `Cells::BulkClaimsWorker` to handle claims outside the database
> transaction. For details and existing patterns, see
> [Bulk claiming for ActiveRecord-bypassing code paths](#bulk-claiming-for-activerecord-bypassing-code-paths).

### Phase 2: Backfilling and verification

Enable the verification worker feature flag
(`cells_claims_verification_worker_<model_name>`) to start the
verification service. On its first run, the service scans every local
record in the model, finds no matching claims in Topology Service, and
creates them. This acts as the backfill for existing data.

After the backfill completes, the verification service continues to run
on a cron schedule. It reconciles local records with Topology Service
claims to detect and correct drift, such as missing claims, orphaned
claims, or changed values.

For details on verification, see
[Verification and backfilling](#verification-and-backfilling).

### Rollout ownership

The feature-owning team owns the rollout of both phases. This includes
creating the feature flags, enabling them, and monitoring that claims
work correctly after enablement.

The Cells Infrastructure team is available to help, but ownership of the
rollout and ensuring correctness belongs to the feature-owning team.

## Feature flags

The claims system uses a hierarchical feature flag structure for
granular control:

### Global feature flag

| Feature flag | Description |
|--------------|-------------|
| `cells_unique_claims` | Primary switch for the entire claims system. Must be enabled for any claims to work. |

### Model-specific feature flags

Each claimable model type has its own feature flag, allowing independent rollout:

| Feature flag | Models | Description |
|--------------|----------|-------------|
| `cells_claims_users` | `User` | Controls claiming of user IDs and usernames |
| `cells_claims_emails` | `Email` | Controls claiming of email addresses |
| `cells_claims_organizations` | `Organization` | Controls claiming of organization paths |
| `cells_claims_namespaces` | `Namespace`, `Group`, `UserNamespace` | Controls claiming of namespace/group IDs |
| `cells_claims_projects` | `Project` | Controls claiming of project IDs |
| `cells_claims_routes` | `Route`, `RedirectRoute` | Controls claiming of route and redirect route paths |
| `cells_claims_keys` | `Key`, `GpgKey`, `DeployKey` | Controls claiming of SSH, GPG and Deploy keys |
| `cells_claims_service_desk_settings` | `ServiceDeskSetting` | Controls claiming of Service Desk custom emails |

### Verification worker feature flags

Each model has a separate feature flag for the verification worker:

| Feature flag | Description |
|--------------|-------------|
| `cells_claims_verification_worker_<model_name>` | Controls whether the verification worker runs for a specific model. Replace `<model_name>` with the [`param_key`](https://gitlab.com/gitlab-org/gitlab/blob/3b96a040fd0a8b8155e77ef733f8cc1275068379/gems/gitlab-utils/lib/gitlab/utils.rb#L75-77). Example: `cells_claims_verification_worker_user` |

### Enabling claims

To enable claims for a specific model, both the global flag and the
model-specific flag must be enabled:

```ruby
# In Rails console

# 1. Enable the global claims system
Feature.enable(:cells_unique_claims)

# 2. Enable claims for specific models
Feature.enable(:cells_claims_users)
Feature.enable(:cells_claims_emails)
Feature.enable(:cells_claims_organizations)

# 3. Enable verification workers for backfilling and ongoing consistency
Feature.enable(:cells_claims_verification_worker_user)
Feature.enable(:cells_claims_verification_worker_email)

# Check all cells claims feature flags
Feature.all.select { |f| f.name.start_with?('cells_claims') }
```

## How to claim attributes

We claim three things for each attribute:

- **The value of the attribute** (defined by `cells_claims_attribute` with required `type` and `feature_flag` parameters)
- **The subject of the record** (defined by `cells_claims_metadata`)
- **The source of the record** (defined by `cells_claims_metadata`)

>[!note]
> Every `cells_claims_attribute` must specify both a `type` (bucket type) and `feature_flag` (model-specific control flag).

### Rails

Using `User` as an example:

```ruby
class User < ApplicationRecord
  include Cells::Claimable

  cells_claims_attribute :id, type: CLAIMS_BUCKET_TYPE::USER_IDS, feature_flag: :cells_claims_users
  cells_claims_attribute :username, type: CLAIMS_BUCKET_TYPE::USERNAMES, feature_flag: :cells_claims_users

  cells_claims_metadata subject_type: CLAIMS_SUBJECT_TYPE::USER, subject_key: :id
end
```

First, include `Cells::Claimable` in the model.

Here we claim two attributes: `id` and `username`. Each attribute requires:

- A `type` (bucket type), which is defined in Topology Service (covered below)
- A `feature_flag` to control when this claim is active (follows naming convention `cells_claims_<model>s`)

Second, define the metadata with `cells_claims_metadata`. Normally you only
need to set `subject_type` and `subject_key`; `source_type` and the source
value are inferred. These must also be defined in Topology Service.

The `subject_type` and `subject_key` identify which record owns the claimed
attribute. This often matches the sharding key, but not always. Use your
judgment when the sharding key doesn't apply.

> [!note]
> Changes to associations are also claimed automatically in the same
> transaction when saving.

#### Adding a new claimable model

When adding claims to a new model:

1. **Create a feature flag** for the model if one doesn't exist:

   ```yaml
   # config/feature_flags/beta/cells_claims_<model>s.yml
   ---
   name: cells_claims_<model>s
   feature_issue_url: https://gitlab.com/gitlab-org/gitlab/-/issues/XXX
   introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/XXX
   rollout_issue_url: https://gitlab.com/gitlab-com/gl-infra/tenant-scale/cells-infrastructure/team/-/issues/XXX
   milestone: 'XX.X'
   group: group::cells infrastructure
   type: beta
   default_enabled: false
   ```

1. **Create a feature flag** for the verification worker:

   ```yaml
   # config/feature_flags/beta/cells_claims_verification_worker_<model_name>.yml
   ---
   name: cells_claims_verification_worker_<model_name>
   feature_issue_url: https://gitlab.com/gitlab-org/gitlab/-/issues/XXX
   introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/XXX
   rollout_issue_url: https://gitlab.com/gitlab-com/gl-infra/tenant-scale/cells-infrastructure/team/-/issues/XXX
   milestone: 'XX.X'
   group: group::cells infrastructure
   type: beta
   default_enabled: false
   ```

1. **Add the claim configuration** to your model:

   ```ruby
   class YourModel < ApplicationRecord
     include Cells::Claimable

     cells_claims_attribute :id, type: CLAIMS_BUCKET_TYPE::YOUR_MODEL_IDS, feature_flag: :cells_claims_your_model
     cells_claims_attribute :unique_attr, type: CLAIMS_BUCKET_TYPE::YOUR_MODEL_ATTRS, feature_flag: :cells_claims_your_model

     cells_claims_metadata subject_type: CLAIMS_SUBJECT_TYPE::YOUR_MODEL, subject_key: :id
   end
   ```

1. **Add types in Topology Service** (see [Topology Service](#topology-service) section)
1. **Audit for ActiveRecord-bypassing code paths** (see [Bulk claiming for ActiveRecord-bypassing code paths](#bulk-claiming-for-activerecord-bypassing-code-paths))
1. **Add tests** (see [Tests](#tests) section)

#### Skip claiming for specific values

Some models should not claim every attribute value. For example:

- `Route` should only claim top-level paths (`gitlab`), not sub-paths (`gitlab/project`).
- `ServiceDeskSetting` should not claim `nil` values in the `custom_email` column.

Use the `if:` option on `cells_claims_attribute` to control which values are claimed.
The `if:` option accepts a lambda that receives the record and returns a boolean.
When `if:` returns `false`, the value is not sent to Topology Service on create and destroy.

```ruby
class Route < ApplicationRecord
  include Cells::Claimable

  cells_claims_attribute :path, type: CLAIMS_BUCKET_TYPE::ROUTES,
    feature_flag: :cells_claims_routes,
    if: ->(record) { record.path.exclude?('/') }
end
```

In this example, only routes without a `/` in the path are claimed.

##### Behavior with `if:`

- **Save (create):** A new claim is created only when `if:` returns `true`.
- **Save (update):** The old value is always destroyed, even if `if:` returned
  `false` when the old value was saved. The new value is created only when
  `if:` returns `true`.
- **Record destroy:** Destroy requests are sent only when `if:` returns true.
- **Verification:** `cells_claims_metadata` excludes entries where `if:`
  returns `false`, so the verification service does not create claims for
  non-claimable values.

##### Scope filtering with `cells_claims_scope`

When the verification service reconciles local records with Topology Service,
it queries all records in the model by default. To exclude rows at the
query level, use the `cells_claims_scope` DSL with a block.

```ruby
class Route < ApplicationRecord
  include Cells::Claimable

  cells_claims_scope do
    where("strpos(path, '/') = 0")
  end

  cells_claims_attribute :path, type: CLAIMS_BUCKET_TYPE::ROUTES,
    feature_flag: :cells_claims_routes,
    if: ->(record) { record.path.exclude?('/') }
end
```

The block must return an `ActiveRecord::Relation`. When no block is
provided, the default scope is `all`. Define a block only when you need
to exclude rows from verification at the database level.

Use `if:` and `cells_claims_scope` together when:

- `if:` controls per-record claiming during save callbacks.
- `cells_claims_scope` controls which records the verification service scans.

If filtering is only needed at the instance level (for example, skipping
`nil` values), use `if:` alone without defining `cells_claims_scope`:

```ruby
class ServiceDeskSetting < ApplicationRecord
  include Cells::Claimable

  cells_claims_attribute :custom_email,
    type: CLAIMS_BUCKET_TYPE::SERVICE_DESK_CUSTOM_EMAILS,
    feature_flag: :cells_claims_service_desk_settings,
    if: ->(record) { record.custom_email.present? }
end
```

#### Bulk claiming for ActiveRecord-bypassing code paths

The `Cells::Claimable` concern relies on ActiveRecord callbacks. Code
paths that use `delete_all`, `insert_all`, `upsert_all`, or raw SQL
bypass these callbacks, so claims are not created or destroyed
automatically.

Audit your model for these code paths. Where they exist, use
`Cells::BulkClaimsWorker` to handle claims. Schedule the worker with
`run_after_commit` to keep claim operations outside the database
transaction.

The worker accepts two payload keys:

- `destroy_metadata`: Pre-built metadata for records to unclaim. Build
  this with `build_destroy_metadata_for_worker` before deleting records,
  because the metadata must be captured while the record still exists.
- `create_record_ids`: An array of record IDs. The worker loads the
  records from the database and builds claim metadata from them.

```ruby
# Destroying claims for records deleted outside ActiveRecord
destroy_metadata = records.filter_map do |record|
  record.build_destroy_metadata_for_worker(:attribute_name)
end

# Creating claims for records inserted outside ActiveRecord
create_record_ids = [record1.id, record2.id]

# Schedule outside the transaction
run_after_commit do
  destroy_metadata.each_slice(Cells::Claimable::BULK_CLAIMS_BATCH_SIZE) do |batch|
    Cells::BulkClaimsWorker.perform_async(
      YourModel.name, 'attribute_name', { 'destroy_metadata' => batch }
    )
  end

  create_record_ids.each_slice(Cells::Claimable::BULK_CLAIMS_BATCH_SIZE) do |batch|
    Cells::BulkClaimsWorker.perform_async(
      YourModel.name, 'attribute_name', { 'create_record_ids' => batch }
    )
  end
end
```

- Use `run_after_commit` to schedule Sidekiq jobs outside the database
  transaction.
- Check `cells_claims_enabled_for_attribute?` before scheduling the
  worker.

For full implementation examples, see
[MR !230849](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230849)
which added bulk claiming for routes and emails.

#### Tests

When we claim something new, we should add tests. We want to add two tests,
one to verify our definitions produce the correct values, and one to verify
they work as expected.

Add this to the model test, using the same user example:

```ruby
it_behaves_like 'cells claimable model',
  subject_type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::USER,
  subject_key: :id,
  source_type: Cells::Claimable::CLAIMS_SOURCE_TYPE::RAILS_TABLE_USERS,
  claiming_attributes: [:id, :username]
```

We can see `source_type` is inferred to `Cells::Claimable::CLAIMS_SOURCE_TYPE::RAILS_TABLE_USERS`.

Next we add a new test file in `spec/cells/claims/user_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Claim for User', feature_category: :cell do
  subject! { build(:user, email: email.email, emails: [email]) }

  let(:email) { build(:email) }

  shared_context 'with claims records for User' do
    def claims_records(only: {})
      claims_records_for(subject, only: only) +
        claims_records_for(email, only: only)
    end
  end

  it_behaves_like 'creating new claims' do
    include_context 'with claims records for User'
  end

  it_behaves_like 'deleting existing claims' do
    include_context 'with claims records for User'
  end

  it_behaves_like 'updating existing claims' do
    let(:transform_attributes) { { username: subject.username.reverse } }

    include_context 'with claims records for User'
  end
end
```

The tricky part is that we need to define `email` even though we're not
defining it in the user model. This is because associations with claiming
attributes are also claimed, such as emails.

That's why we override `claims_records`. By default it'll only produce claims
for the subject itself, but here we also need to claim the emails together.

We have three shared examples:

- creating new claims
- deleting existing claims
- updating existing claims

All three require overriding `claims_records`. For updating existing claims,
we also need to define `transform_attributes` for the claims that we want to
update. Here we reverse the username, and the tests verify that the old claims
are destroyed and new claims are created.

If this record will never be updated, then the `updating existing claims`
tests can be omitted.

##### Testing feature flag behavior

To test that claims respect feature flags:

```ruby
RSpec.describe 'Claim for YourModel', feature_category: :cell do
  context 'when cells_claims_your_model feature flag is enabled' do
    it_behaves_like 'creating new claims'
    it_behaves_like 'deleting existing claims'
  end

  context 'when cells_claims_your_model feature flag is disabled' do
    before do
      stub_feature_flags(cells_claims_your_model: false)
    end

    it_behaves_like 'not creating claims'
    it_behaves_like 'not deleting claims'
  end
end
```

### Topology Service

The types we're using are defined in Topology Service, under:
[`proto/claims/v1/messages.proto`](https://gitlab.com/gitlab-org/cells/topology-service/-/blob/f1a172d3c09e3aac7d3242c088a0261c9c01f5f7/proto/claims/v1/messages.proto)

For each new claim, we want to add a new type under:

- [Bucket::Type](https://gitlab.com/gitlab-org/cells/topology-service/-/blob/977b7144a5ef619f626b9b2bab1ea2d53ad40552/proto/claims/v1/messages.proto#L11)
- [Subject::Type](https://gitlab.com/gitlab-org/cells/topology-service/-/blob/977b7144a5ef619f626b9b2bab1ea2d53ad40552/proto/claims/v1/messages.proto#L31) (might exist already)
- [Source::Type](https://gitlab.com/gitlab-org/cells/topology-service/-/blob/977b7144a5ef619f626b9b2bab1ea2d53ad40552/proto/claims/v1/messages.proto#L44)

Here's the workflow to make new types available for Rails:

- Create a merge request in [Topology Service](https://gitlab.com/gitlab-org/cells/topology-service)
  to add new types in `proto/claims/v1/messages.proto`
- **Add validation rules** for the new bucket type in the [validation.go](https://gitlab.com/gitlab-org/cells/topology-service/-/blob/977b7144a5ef619f626b9b2bab1ea2d53ad40552/internal/services/claim/rules/validation.go#L10) file to prevent incorrect usage (see [validation docs](https://gitlab.com/gitlab-org/cells/topology-service/-/blob/977b7144a5ef619f626b9b2bab1ea2d53ad40552/docs/claims.md#validation))
- After it's reviewed and merged, create a merge request in [GitLab](https://gitlab.com/gitlab-org/gitlab)
  to update the Topology Service client, by running
  `scripts/update-topology-service-gem.sh` in the merge request branch
- After it's reviewed and merged, it should be available in the GitLab
  default branch

## Verification and backfilling

The verification service (`Cells::Claims::VerificationService`) reconciles
local database records with claims stored in Topology Service. It serves
two purposes:

- **Backfilling:** When first enabled for a model, the service scans all
  local records that have no corresponding claims in Topology Service and
  creates them.
- **Ongoing consistency:** After backfilling, the service continues to run
  on a cron schedule to detect and correct drift.

### How verification works

The `ScheduleClaimsVerificationWorker` cron job schedules a
`ClaimsVerificationWorker` for each claimable model, staggered by
10 minutes.

Each worker run:

1. Acquires an exclusive lease (5-minute TTL) to prevent concurrent runs
   for the same model.
1. Scans local records in batches of 1000, ordered by primary key.
1. Fetches corresponding claims from Topology Service for each batch range.
1. Compares local records against Topology Service claims:
   - Local records with no matching claim: creates the claim.
   - Topology Service claims with no matching local record: destroys
     the claim.
   - Records where claim metadata differs: destroys the old claim and
     creates the corrected one.
1. Skips records updated within the last hour to avoid conflicts with
   in-flight saves.
1. Persists progress (last processed ID) to Redis after each batch. If
   the worker runs out of time (4.5-minute limit), it reschedules itself
   to continue from where it stopped.

### Enable the verification worker

Create a feature flag for the verification worker and enable it after
the model-specific claiming flag is active:

```ruby
# Enable after the model claiming flag is already enabled
Feature.enable(:cells_claims_verification_worker_user)
```

The verification worker flag follows the naming convention
`cells_claims_verification_worker_<model_name>`, where `<model_name>`
is the parameterized model name (for example, `user`, `email`, `route`).

## Validation

After defining claims attributes, Rails automatically claims attributes when
creating, updating, or deleting records. These claims are sent to Topology
Service, which stores them in its database. In GDK, Topology Service uses
the local PostgreSQL database by default. We can access the `psql` console by
running `gdk psql -d topology_service`. As an example, we can use this
command to list all the claims:

```shell
gdk psql -d topology_service -c "SELECT * FROM claims;"
```

You can play around and create, update, and delete a few records by using
the web UI, and then run this command from time to time to verify it's
working as expected.

## Troubleshooting

### Claims not being created

1. **Check global feature flag:**

   ```ruby
   Feature.enabled?(:cells_unique_claims)
   ```

1. **Check model-specific feature flag:**

   ```ruby
   Feature.enabled?(:cells_claims_users)  # Replace with your model's flag
   ```

1. **Verify Topology Service is running:**

   ```shell
   gdk status gitlab-topology-service
   ```

1. **Check Topology Service logs:**

   ```shell
   gdk tail gitlab-topology-service
   ```

### Backfill not progressing

1. **Check the verification worker feature flag:**

   ```ruby
   Feature.enabled?(:cells_claims_verification_worker_user)  # Replace with your model
   ```

1. **Check verification worker logs** for batch progress. Look for
   `Cells::Claims::VerificationService batch processed` log entries
   with `created` and `destroyed` counts.

1. **Check Redis for progress state.** The worker stores the last
   processed ID. If the worker keeps restarting from ID 0, verify
   the Redis key exists:

   ```ruby
   Gitlab::Redis::SharedState.with do |redis|
     redis.get("cells:claims:verification_service:last_processed_id:User")  # Replace User with your model name
   end
   ```
