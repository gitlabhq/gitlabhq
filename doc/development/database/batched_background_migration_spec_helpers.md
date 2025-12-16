---
stage: Data Stores
group: Database
title: Batched Background Migration Spec Helpers
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

The versioned spec helper library for batched background migrations
reduces boilerplate code in migration specs.

## Spec helper features

Batched background migration specs often require defining multiple table helpers using
the `table()` method from `MigrationsHelpers`. This results in repetitive code:

```ruby
# Without helpers - repetitive
RSpec.describe Gitlab::BackgroundMigration::BackfillProjectId do
  let!(:projects) { table(:projects) }
  let!(:issues) { table(:issues) }
  let!(:notes) { table(:notes) }
  let!(:users) { table(:users) }
  # ... more table definitions
end
```

The batched background migration spec helpers eliminate this repetition through
lazy evaluation and memoization:

```ruby
# With helpers - clean and concise
RSpec.describe Gitlab::BackgroundMigration::BackfillProjectId do
  include Gitlab::BackgroundMigration::SpecHelpers::V1

  # Declare the tables you need
  tables :projects, :issues, :notes, :users
end
```

## Versioning

The helpers are versioned to ensure backward compatibility. When modifications are needed,
a new version can be created without breaking existing specs.

### Available Versions

- **V1**: Initial version with table helpers (current)

### Using a Specific Version

Include the version module you want to use:

```ruby
RSpec.describe Gitlab::BackgroundMigration::SomeMigration do
  include Gitlab::BackgroundMigration::SpecHelpers::V1
end
```

## Features

### Explicit Table Declaration

Tables must be explicitly declared using the `tables` method before they can be accessed:

```ruby
RSpec.describe Gitlab::BackgroundMigration::BackfillNamespaceId do
  include Gitlab::BackgroundMigration::SpecHelpers::V1

  # Declare all tables needed in your spec
  tables :issues, :namespaces, :projects

  it 'backfills namespace_id' do
    # Tables are created on first access after declaration
    namespace = namespaces.create!(name: 'test', path: 'test')
    project = projects.create!(namespace_id: namespace.id)
    issue = issues.create!(project_id: project.id)
  end
end
```

### Memoization

Table helpers are memoized, so repeated access returns the same instance:

```ruby
RSpec.describe Gitlab::BackgroundMigration::SomeMigration do
  include Gitlab::BackgroundMigration::SpecHelpers::V1

  tables :users

  it 'uses memoized tables' do
    users_1 = users  # Creates the helper on first access
    users_2 = users  # Returns the same instance

    expect(users_1).to be(users_2)
  end
end
```

### Custom Configuration

You can configure tables with custom options:

#### Custom Primary Key

```ruby
RSpec.describe Gitlab::BackgroundMigration::SomeMigration do
  include Gitlab::BackgroundMigration::SpecHelpers::V1

  tables :custom_table
  configure_table :custom_table, primary_key: :custom_id

  it 'uses custom primary key' do
    record = custom_table.create!(custom_id: 1, name: 'test')
    expect(custom_table.primary_key).to eq('custom_id')
  end
end
```

#### Custom Database

```ruby
RSpec.describe Gitlab::BackgroundMigration::SomeMigration do
  include Gitlab::BackgroundMigration::SpecHelpers::V1

  tables :ci_builds
  configure_table :ci_builds, database: :ci
end
```

#### Partitioned Tables

```ruby
RSpec.describe Gitlab::BackgroundMigration::SomeMigration, migration: :gitlab_ci do
  include Gitlab::BackgroundMigration::SpecHelpers::V1

  tables :p_ci_builds
  configure_table :p_ci_builds, partitioned: true, database: :ci

  it 'works with partitioned tables' do
    build = p_ci_builds.create!(partition_id: 100, project_id: 1)
  end
end
```

## Migration Guide

### Converting Existing Specs

To convert an existing spec to use the helpers:

**Before:**

```ruby
RSpec.describe Gitlab::BackgroundMigration::BackfillProjectId,
  feature_category: :code_review_workflow,
  schema: 20240501044347 do

  let!(:projects) { table(:projects) }
  let!(:merge_requests) { table(:merge_requests) }
  let!(:approval_rules) { table(:approval_merge_request_rules) }

  it 'backfills project_id' do
    project = projects.create!(name: 'test')
    mr = merge_requests.create!(target_project_id: project.id)
    rule = approval_rules.create!(merge_request_id: mr.id)

    # test logic
  end
end
```

**After:**

```ruby
RSpec.describe Gitlab::BackgroundMigration::BackfillProjectId,
  feature_category: :code_review_workflow,
  schema: 20240501044347 do

  include Gitlab::BackgroundMigration::SpecHelpers::V1

  tables :approval_merge_request_rules, :merge_requests, :projects

  it 'backfills project_id' do
    project = projects.create!(name: 'test')
    mr = merge_requests.create!(target_project_id: project.id)
    rule = approval_merge_request_rules.create!(merge_request_id: mr.id)

    # test logic
  end
end
```

### When to Use

**Use the helpers when:**

- Writing new batched background migration specs
- You need multiple table helpers
- You want to reduce boilerplate code

**Consider manual definitions when:**

- You need specific table configurations
- You're working with complex custom table setups
- The spec only uses one or two tables

## Best Practices

1. **Always declare tables explicitly** - Use the `tables` method to declare all tables needed in your spec. Tables are not automatically available and must be declared before use.
1. **Declare tables in alphabetical order** - This improves consistency and readability across specs.
1. **Use the latest version** - Use V1 (or the latest available version) for new specs unless there's a specific reason not to.
1. **Configure after declaring** - Always declare tables with `tables` first, then configure them with `configure_table` if needed.
1. **Don't mix approaches** - Either use the spec helpers or manual `let!` definitions, not both in the same spec.
1. **Keep configurations minimal** - Only configure tables when you need custom options (primary keys, databases, partitioning).

## Troubleshooting

### Table Not Found

If you get a "table not found" error, ensure:

1. You've declared the table using `tables :table_name` at the class level
1. The table exists in the schema version specified in your spec
1. You're using the correct database (`:main`, `:ci`, etc.)
1. The migration metadata is set correctly

### Primary Key Issues

If you have primary key errors:

1. Check if the table uses a custom primary key
1. Configure it explicitly: `configure_table :table_name, primary_key: :custom_id`

### Partitioned Table Issues

For partitioned tables:

1. Ensure you've marked the spec with the correct migration type:
   `migration: :gitlab_ci`
1. Configure the table as partitioned:
   `configure_table :p_ci_builds, partitioned: true`
1. Specify the database if needed: `database: :ci`

## Future Versions

When new versions are released, this document is updated with:

- Migration guides from older versions
- New features in each version
- Deprecation notices
