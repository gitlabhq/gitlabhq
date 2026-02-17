---
stage: Runtime
group: Cells Infrastructure
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
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

## Feature flags

The claims system uses a hierarchical feature flag structure for granular control:

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

### Enabling claims

To enable claims for a specific model, **both** the global flag and the model-specific flag must be enabled:

```ruby
# In Rails console

# 1. Enable the global claims system
Feature.enable(:cells_unique_claims)

# 2. Enable claims for specific models
Feature.enable(:cells_claims_users)
Feature.enable(:cells_claims_emails)
Feature.enable(:cells_claims_organizations)

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

1. **Add tests** (see [Tests](#tests) section)

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
