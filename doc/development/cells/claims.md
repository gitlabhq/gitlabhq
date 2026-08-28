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

Claiming a new attribute requires two phases, each serving a distinct purpose.
The per-attribute `feature_flag:` gates both phases: live claiming skips a
disabled attribute, and so does verification.

### Phase 1: Live request claiming

Add the `Cells::Claimable` concern to the model and, optionally, a temporary
`feature_flag:` for the new attribute's rollout. When claiming is enabled,
Rails `after_save` and `before_destroy` callbacks claim and release
attributes in Topology Service for every create, update, and delete.

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

The verification service starts automatically once the model has at least one
claimable attribute enabled. On its first run, the service scans every local
record in the model, finds no matching claims in Topology Service, and
creates them. This acts as the backfill for existing data.

After the backfill completes, the verification service continues to run
on a cron schedule. It reconciles local records with Topology Service
claims to detect and correct drift, such as missing claims, orphaned
claims, or changed values.

The service only reconciles attributes that are currently enabled. An
attribute still behind its `feature_flag:` is skipped by backfill and
drift correction, the same as it is by live claiming.

For details on verification, see
[Verification and backfilling](#verification-and-backfilling).

### Rollout ownership

The feature-owning team owns the rollout of both phases. This includes
creating any temporary rollout feature flag, enabling it, and monitoring
that claims work correctly after enablement.

The Cells Infrastructure team is available to help, but ownership of the
rollout and ensuring correctness belongs to the feature-owning team.

## Feature flags

### Global feature flag

| Feature flag | Description |
|--------------|-------------|
| `cells_unique_claims` | Primary switch for the entire claims system. Must be enabled for any claims to work. |

### Enabling claims

With cells and the global flag enabled, a model's attributes are claimed
without any further configuration, unless an individual attribute still
carries a temporary `feature_flag:` for rollout
(see [How to claim attributes](#how-to-claim-attributes)).
The verification worker for a model runs automatically when at least one of
the model's attributes is enabled, so there's no separate step to
enable it. See
[Enable the verification worker](#enable-the-verification-worker).

```ruby
# In Rails console

# Enable the global claims system
Feature.enable(:cells_unique_claims)

# Check all cells claims feature flags, including any temporary
# per-attribute rollout flags
Feature.all.select { |f| f.name.start_with?('cells_claims') }
```

## How to claim attributes

We claim three things for each attribute:

- **The value of the attribute** (defined by `cells_claims_attribute` with a
  required `type` parameter and an optional `feature_flag` parameter)
- **The subject of the record** (defined by `cells_claims_metadata`)
- **The source of the record** (defined by `cells_claims_metadata`)

>[!note]
> Every `cells_claims_attribute` must specify a `type` (claim type). An
> optional `feature_flag` can be added for deployment safety when first
> rolling out claims for a new attribute. It is part of the rollout
> lifecycle, not a permanent requirement, and should be removed once the
> attribute has been validated and stable in production. See
> [Removing the feature flag](#removing-the-feature-flag).

### Rails

Using `User` as an example:

```ruby
class User < ApplicationRecord
  include Cells::Claimable

  cells_claims_attribute :id, type: CLAIMS_CLAIM_TYPE::CLAIM_TYPE_USER_ID
  cells_claims_attribute :username, type: CLAIMS_CLAIM_TYPE::CLAIM_TYPE_USERNAME

  cells_claims_metadata subject_type: CLAIMS_SUBJECT_TYPE::USER, subject_key: :id
end
```

First, include `Cells::Claimable` in the model.

Here we claim two attributes: `id` and `username`. Each attribute requires a
`type` (claim type), which is defined in Topology Service (covered below).
Neither attribute has a `feature_flag` here because both were validated in
production and their temporary rollout flags were removed. See
[Adding a new claimable model](#adding-a-new-claimable-model) for an example
that still uses `feature_flag`.

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

1. **Create a temporary feature flag** for the new attribute's rollout:

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

1. **Add the claim configuration** to your model:

   ```ruby
   class YourModel < ApplicationRecord
     include Cells::Claimable

     cells_claims_attribute :id, type: CLAIMS_CLAIM_TYPE::CLAIM_TYPE_YOUR_MODEL_ID, feature_flag: :cells_claims_your_model
     cells_claims_attribute :unique_attr, type: CLAIMS_CLAIM_TYPE::CLAIM_TYPE_YOUR_MODEL_ATTR, feature_flag: :cells_claims_your_model

     cells_claims_metadata subject_type: CLAIMS_SUBJECT_TYPE::YOUR_MODEL, subject_key: :id
   end
   ```

1. **Add types in Topology Service** (see [Topology Service](#topology-service) section)
1. **Audit for ActiveRecord-bypassing code paths** (see [Bulk claiming for ActiveRecord-bypassing code paths](#bulk-claiming-for-activerecord-bypassing-code-paths))
1. **Add tests** (see [Tests](#tests) section)

#### Removing the feature flag

A new claimable attribute should always be introduced behind a temporary
`feature_flag:`, so the rollout can be controlled and reverted independently
of the rest of the model. This is a step in the rollout lifecycle, not a
permanent requirement: the flag exists for deployment safety and is removed
once the attribute has been validated in production.

After enabling the flag globally in production, validate that the attribute
lifecycle works end to end:

- **Create:** creating a record claims the attribute.
- **Delete:** destroying a record releases the claim.
- **Rename:** updating the attribute releases the old claim and creates the new one.

Once claiming has run without issue in production for at least a week, remove
the per-attribute `feature_flag:` and delete the flag's YAML file. After removal,
only `Gitlab.config.cell.enabled` controls claiming, as
`cells_claims_enabled_for_attribute?` returns `true` when no `feature_flag` is
set. See [`Cells::Claimable`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/concerns/cells/claimable.rb).

Because the same flag gates verification, removing it also starts backfill
and drift correction for the attribute, in addition to live claiming. See
[Enable the verification worker](#enable-the-verification-worker).

For an example of this cleanup, see [merge request 240942](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240942),
which removed the `cells_claims_service_desk_settings` flag from `ServiceDeskSetting`.

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

  cells_claims_attribute :path, type: CLAIMS_CLAIM_TYPE::CLAIM_TYPE_ROUTE,
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

  cells_claims_attribute :path, type: CLAIMS_CLAIM_TYPE::CLAIM_TYPE_ROUTE,
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
    type: CLAIMS_CLAIM_TYPE::CLAIM_TYPE_SERVICE_DESK_CUSTOM_EMAIL,
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

If your new attribute is introduced behind a temporary `feature_flag:`, test
that claims respect it. Replace `cells_claims_your_new_attribute` with the
flag you created:

```ruby
RSpec.describe 'Claim for YourModel', feature_category: :cell do
  context 'when cells_claims_your_new_attribute feature flag is enabled' do
    it_behaves_like 'creating new claims'
    it_behaves_like 'deleting existing claims'
  end

  context 'when cells_claims_your_new_attribute feature flag is disabled' do
    before do
      stub_feature_flags(cells_claims_your_new_attribute: false)
    end

    it_behaves_like 'not creating claims'
    it_behaves_like 'not deleting claims'
  end
end
```

Once the flag is removed, these examples for the disabled state no longer apply.

### Topology Service

The types we're using are defined in Topology Service. The claim type lives in
[`proto/types/v1/claim.proto`](https://gitlab.com/gitlab-org/cells/topology-service/-/blob/f3dbc2c643df244162f7144f24579fc5651f5db8/proto/types/v1/claim.proto),
and the subject and source types live in
[`proto/claims/v1/messages.proto`](https://gitlab.com/gitlab-org/cells/topology-service/-/blob/f1a172d3c09e3aac7d3242c088a0261c9c01f5f7/proto/claims/v1/messages.proto).

For each new claim, we want to add a new type under:

- [`oneof claim`](https://gitlab.com/gitlab-org/cells/topology-service/-/blob/f3dbc2c643df244162f7144f24579fc5651f5db8/proto/types/v1/claim.proto#L12)
- [ClaimType](https://gitlab.com/gitlab-org/cells/topology-service/-/blob/f3dbc2c643df244162f7144f24579fc5651f5db8/proto/types/v1/claim.proto#L77)
- [Subject::Type](https://gitlab.com/gitlab-org/cells/topology-service/-/blob/977b7144a5ef619f626b9b2bab1ea2d53ad40552/proto/claims/v1/messages.proto#L31) (might exist already)
- [Source::Type](https://gitlab.com/gitlab-org/cells/topology-service/-/blob/977b7144a5ef619f626b9b2bab1ea2d53ad40552/proto/claims/v1/messages.proto#L44)

Here's the workflow to make new types available for Rails:

- Create a merge request in [Topology Service](https://gitlab.com/gitlab-org/cells/topology-service)
  to add the new claim type in `proto/types/v1/claim.proto` (and the subject or
  source type in `proto/claims/v1/messages.proto` if needed)
- **Add validation rules** for the new claim type in the [validation.go](https://gitlab.com/gitlab-org/cells/topology-service/-/blob/977b7144a5ef619f626b9b2bab1ea2d53ad40552/internal/services/claim/rules/validation.go#L10) file to prevent incorrect usage (see [validation docs](https://gitlab.com/gitlab-org/cells/topology-service/-/blob/977b7144a5ef619f626b9b2bab1ea2d53ad40552/docs/claims.md#validation))
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

The service only reconciles attributes where `cells_claims_enabled_for_attribute?`
is `true`. If every attribute of a model is disabled, the service logs a
warning and skips the model. Claims already written for an attribute that is
later disabled are left in place. They are not fetched or destroyed.

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

There's no separate step to enable the verification worker.
`Cells::ClaimsVerificationWorker#enabled?` determines whether verification
runs for a model:

```ruby
def enabled?(model)
  return false unless Cells::Claimable.models_with_claims.include?(model)

  model.cells_claims_attributes.any? { |attribute, _| model.cells_claims_enabled_for_attribute?(attribute) }
end
```

Verification runs for a model when the model is registered in
`Cells::Claimable.models_with_claims` (declaring a `cells_claims_attribute`
registers it) and at least one of its attributes is currently claimable, as
determined by `cells_claims_enabled_for_attribute?`. Within a run, the service
reconciles only the attributes that are enabled, so an attribute still behind a
`feature_flag:` is skipped without holding back the rest of the model.

For a model whose attributes carry no temporary `feature_flag:`, verification
runs as soon as `Gitlab.config.cell.enabled` is `true`, with no further
configuration.

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

1. **Check whether the attribute is claimable:**

   ```ruby
   # Replace User and :id with your model and attribute
   User.cells_claims_enabled_for_attribute?(:id)
   ```

   This returns `false` unless `Gitlab.config.cell.enabled` is `true`, and,
   if the attribute still has a temporary `feature_flag:`, unless that flag
   is also enabled.

1. **Verify Topology Service is running:**

   ```shell
   gdk status gitlab-topology-service
   ```

1. **Check Topology Service logs:**

   ```shell
   gdk tail gitlab-topology-service
   ```

### Backfill not progressing

1. **Check whether verification is enabled for the model:**

   ```ruby
   # Replace User with your model
   User.cells_claims_attributes.each do |attribute, _|
     puts "#{attribute}: #{User.cells_claims_enabled_for_attribute?(attribute)}"
   end
   ```

   Verification only runs when if at least one attribute prints `true`. A single
   attribute stuck behind a temporary `feature_flag:` pauses verification
   for the whole model.

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
