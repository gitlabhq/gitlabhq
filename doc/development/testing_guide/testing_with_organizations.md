---
stage: Tenant Scale
group: Organizations
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Writing tests with Organizations
---

## Organization Isolation: The "Common Organization"

In most cases, features will not cross organization boundaries.
That means that tests should also be contained in one organization.
And created data should share the same organization.
But we want to avoid developers having to manually ensure data to be part of the same organization.

The factories for `User` and `Project` will create a `common_organization` behind the scenes, that will be used for both object instances:

```ruby
let(:user) { create(:user) }
let(:project) { create(:project) }

# this is true:
user.organization == project.organization
```

If an ActiveRecord model needs an organization, it is best to use the common organization in the factory as
a default value for `organization`:

```ruby
FactoryBot.define do
  factory :sbom_component, class: 'Sbom::Component' do
    organization { association :common_organization }
  end
end
```

## Creating users

For the first iterations of Cells, a User will be member of only one organization. However, the database design supports membership of multiple organizations. Because of this, `User` instances have two methods related to organizations:

- `organizations`: the Organizations that the User is a member of.
- `organization`: the sharding key: the Organization that 'owns' the user.

Some examples:

```ruby
# Creates a user in the common organization
let(:user1) { create(:user) }

# Creates a user in another organization
let(:user2) { create(:user, organization: other_organization) }

# Creates a user in both organizations, org1 will be used for the sharding key
let(:user3) { create(:user, organizations: [org1, org2])}
```

> [!note]
> Except for some edge cases, there is no need to test user membership of multiple organizations.

## Writing tests for code that depends on `Current.organization`

If you need a `Current.organization` for tests, you can use the [`with_current_organization`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/support/shared_contexts/current_organization_context.rb) shared context.
This will create a `current_organization` method that will be returned by `Gitlab::Current::Organization` class

```ruby
# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ProjectsController, :with_current_organization do
  let(:project) { create(:project) }

  it 'sets Current.organization' do
    get :index

    expect(Current.organization).to eq(project.organization)
  end
end
```
