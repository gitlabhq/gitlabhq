---
stage: Enablement
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Update multiple database objects

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/32921) in GitLab 13.5.

You can update multiple database objects with new values for one or more columns.
One method is to use `Relation#update_all`:

```ruby
user.issues.open.update_all(due_date: 7.days.from_now) # (1)
user.issues.update_all('relative_position = relative_position + 1') # (2)
```

If you cannot express the update as either a static value (1) or as a calculation (2),
use `UPDATE FROM` to express the need to update multiple rows with distinct values
in a single query. Create a temporary table, or a Common Table Expression (CTE),
and use it as the source of the updates:

```sql
with updates(obj_id, new_title, new_weight) as (
  values (1 :: integer, 'Very difficult issue' :: text, 8 :: integer),
         (2, 'Very easy issue', 1)
)
update issues
  set title = new_title, weight = new_weight
  from updates
  where id = obj_id
```

You can't express this in ActiveRecord, or by dropping down to [Arel](https://api.rubyonrails.org/v6.1.0/classes/Arel.html),
because the `UpdateManager` does not support `update from`. However, we supply
an abstraction to help you generate these kinds of updates: `Gitlab::Database::BulkUpdate`.
This abstraction constructs queries like the previous example, and uses
binding parameters to avoid SQL injection.

## Usage

To use `Gitlab::Database::BulkUpdate`, we need:

- The list of columns to update.
- A mapping from the object (or ID) to the new values to set for that object.
- A way to determine the table for each object.

For example, we can express the example query in a way that determines the
table by calling `object.class.table_name`:

```ruby
issue_a = Issue.find(..)
issue_b = Issue.find(..)

# Issues a single query:
::Gitlab::Database::BulkUpdate.execute(%i[title weight], {
  issue_a => { title: 'Very difficult issue', weight: 8 },
  issue_b => { title: 'Very easy issue', weight: 1 }
})
```

You can even pass heterogeneous sets of objects, if the updates all make sense
for them:

```ruby
issue_a = Issue.find(..)
issue_b = Issue.find(..)
merge_request = MergeRequest.find(..)

# Issues two queries
::Gitlab::Database::BulkUpdate.execute(%i[title], {
  issue_a => { title: 'A' },
  issue_b => { title: 'B' },
  merge_request => { title: 'B' }
})
```

If your objects do not return the correct model class, such as if they are part
of a union, then specify the model class explicitly in a block:

```ruby
bazzes = params
objects = Foo.from_union([
    Foo.select("id, 'foo' as object_type").where(quux: true),
    Bar.select("id, 'bar' as object_type").where(wibble: true)
    ])
# At this point, all the objects are instances of Foo, even the ones from the
# Bar table
mapping = objects.to_h { |obj| [obj, bazzes[obj.id]] }

# Issues at most 2 queries
::Gitlab::Database::BulkUpdate.execute(%i[baz], mapping) do |obj|
  obj.object_type.constantize
end
```

## Caveats

This tool is **very low level**, and operates directly on the raw column
values. You should consider these issues if you implement it:

- Enumerations and state fields must be translated into their underlying
  representations.
- Nested associations are not supported.
- No validations or hooks are called.
