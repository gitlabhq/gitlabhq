---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 'Development Guidelines: Organization data isolation'
title: Organization data isolation
---

The `gitlab-database-data_isolation` gem provides row-level
data isolation for shared tables. It's the query-scoping mechanism
behind [Organization isolation](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/organization/isolation/),
and is a prerequisite for [Protocells](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/protocells/).

Data isolation was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/226037) in GitLab 19.0
behind a feature flag named `data_isolation`, which is disabled by default.

## Purpose of data isolation

An organization acts like a container for customer data: All data for a customer belongs
to one organization. Organizations are isolated by design: An organization can't reference
data in another organization.

GitLab uses shared infrastructure: One GitLab instance can have one or more organizations.
This means we need a mechanism to ensure that data from one organization cannot leak into
another organization.

The `gitlab-database-data_isolation` gem prevents this behavior by transparently rewriting
`ActiveRecord` queries against tables that have a [sharding key](../database/database_dictionary.md#sharding-key-fields)
configured.

It works by injecting an additional `WHERE` clause on the `FROM` table before the query
is sent to the database. For example:

```sql
SELECT "users"."id" FROM "users" WHERE "users"."username" = 'some_user'
# Scoped:
SELECT "users"."id" FROM "users" WHERE "users"."username" = 'some_user' AND "users"."organization_id" = 1000
```

## Implementation

- The code is implemented as a gem and is available in [`gems/gitlab-database-data_isolation`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-database-data_isolation).
- The gem supports different strategies. It uses the Arel strategy, which operates on the query representation used by ActiveRecord.
- In [`config/initializers/gitlab_database_data_isolation.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/gitlab_database_data_isolation.rb), the gem is wired
  into the monolith.
- [`Gitlab::Organizations::Isolation.enabled?`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/organizations/isolation.rb) determines if isolation should be applied. This check
  is run for each query.

## Known issues

- Only queries processed by ActiveRecord are supported.
- `UPDATE`, `DELETE`, and `INSERT` statements are not isolated.

## Enable data isolation

Isolation is applied to a query only when all of the following are true:

- The feature flag is enabled: `Feature.enable(:data_isolation)`.
- `Current.organization` is assigned.
- The current organization is marked as isolated. To mark all organizations:
  `Organizations::Organization.find_each(&:mark_as_isolated!)`.

## Example

To see the isolation in action, run the following script in the Rails console:

```ruby
Feature.enable(:data_isolation)
my_org = Organizations::Organization.find_or_create_by!(path: 'my-org') { |org| org.name = 'My Org' }
puts my_org.isolated? # initially, the organization is not isolated
Current.organization = my_org

# my_org is not isolated, so this prints the organization ID of the first project:
puts Project.first.organization.id

# Mark my_org as isolated and repeat:
my_org.mark_as_isolated!
puts Project.first # prints nil, because no project belongs to my-org

# Bypass the isolation:
Gitlab::Database::DataIsolation::ScopeHelper.without_data_isolation do
  puts Project.first.organization.id # No longer isolated, so it will print the organization id
end
```

## When to bypass query scoping

Possible reasons:

- Intentional cross-organization data access. For example, for admin tooling.
- Poor query performance. The query modification may result in inefficient queries.
