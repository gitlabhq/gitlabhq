---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: '`CHECK` constraints'
---

Use `CHECK` constraints to enforce data integrity rules beyond `NOT NULL` requirements.
For `NOT NULL` constraints specifically, see [`NOT NULL` constraints](not_null_constraints.md).

## Add a `CHECK` constraint to a new column with a default value

When you add a new column with a `CHECK` constraint and a default value that satisfies
the constraint, you can skip constraint validation in the initial migration.
Validate the constraint in a post-deployment migration instead.

This approach avoids a full table scan on large tables because:

- Existing rows resolve to the default value through the PostgreSQL
  [fast defaults](https://www.postgresql.org/docs/current/ddl-alter.html#DDL-ALTER-ADDING-A-COLUMN)
  mechanism, so the constraint is already satisfied.
- A `NOT VALID` constraint is still enforced on new inserts and updates,
  so future rows cannot violate it.

This pattern only applies when the default value expression itself satisfies the
constraint. For example, a literal string value like `'active'` is safe, but a function
call or expression that could produce invalid values should not use this pattern.

### Add the column with constraint and default value

Create a regular migration that adds the column and the `CHECK` constraint with `validate: false`:

```ruby
class AddStatusCheckToProjects < Gitlab::Database::Migration[2.1]
  def change
    add_column :projects, :status, :string, default: 'active'
    add_check_constraint :projects, "status IN ('active', 'inactive')", name: 'check_status_valid', validate: false
  end
end
```

### Validate the constraint

After you have added the column, in a post-deployment migration in the same release, validate the constraint.
See the [migration style guide](../migration_style_guide.md) for more information
on post-deployment migrations:

```ruby
class ValidateProjectsStatusCheckConstraint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    validate_check_constraint :projects, name: 'check_status_valid'
  end

  def down
    # no-op
  end
end
```
