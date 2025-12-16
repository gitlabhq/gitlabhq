---
stage: Runtime
group: Cells Infrastructure
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Claiming an attribute for a cell
---

{{< alert type="flag" >}}

Both [cells](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/cells.md#setting-up-cells-locally)
and feature flag `Feature.enabled?(:cells_unique_claims)` have to be enabled
for this to take effect.

{{< /alert >}}

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

## How to claim attributes

We claim three things for each attribute:

- The value of the attribute (defined by `cells_claims_attribute`)
- The subject of the record (defined by `cells_claims_metadata`)
- The source of the record (defined by `cells_claims_metadata`)

### Rails

Using `User` as an example:

```ruby
class User < ApplicationRecord
  include Cells::Claimable

  cells_claims_attribute :id, type: CLAIMS_BUCKET_TYPE::USER_IDS
  cells_claims_attribute :username, type: CLAIMS_BUCKET_TYPE::USERNAMES

  cells_claims_metadata subject_type: CLAIMS_SUBJECT_TYPE::USER, subject_key: :id
end
```

First, include `Cells::Claimable` in the model.

Here we claim two attributes: `id` and `username`. Each attribute requires
a bucket type, which is defined in Topology Service (covered below).

Second, define the metadata with `cells_claims_metadata`. Normally you only
need to set `subject_type` and `subject_key`; `source_type` and the source
value are inferred. These must also be defined in Topology Service.

The `subject_type` and `subject_key` identify which record owns the claimed
attribute. This often matches the sharding key, but not always. Use your
judgment when the sharding key doesn't apply.

{{< alert type="note" >}}

Changes to associations are also claimed automatically in the same
transaction when saving.

{{< /alert >}}

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

### Topology Service

The types we're using are defined in Topology Service, under:
[`proto/claims/v1/messages.proto`](https://gitlab.com/gitlab-org/cells/topology-service/-/blob/f1a172d3c09e3aac7d3242c088a0261c9c01f5f7/proto/claims/v1/messages.proto)

For each new claim, we want to add a new type under:

- Bucket::Type
- Subject::Type (might exist already)
- Source::Type

Here's the workflow to make new types available for Rails:

- Create a merge request in [Topology Service](https://gitlab.com/gitlab-org/cells/topology-service)
  to add new types in `proto/claims/v1/messages.proto`
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
