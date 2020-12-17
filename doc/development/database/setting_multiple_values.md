---
stage: Enablement
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Setting Multiple Values

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/32921) in GitLab 13.5.

There's often a need to update multiple objects with new values for one
or more columns. One method of doing this is using `Relation#update_all`:

```ruby
user.issues.open.update_all(due_date: 7.days.from_now) # (1)
user.issues.update_all('relative_position = relative_position + 1') # (2)
```

But what do you do if you cannot express the update as either a static value (1)
or as a calculation (2)?

Thankfully we can use `UPDATE FROM` to express the need to update multiple rows
with distinct values in a single query. One can either use a temporary table, or
a Common Table Expression (CTE), and then use that as the source of the updates:

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

The bad news: there is no way to express this in ActiveRecord or even dropping
down to ARel. The `UpdateManager` does not support `update from`, so this
is not expressible.

The good news: we supply an abstraction to help you generate these kinds of
updates, called `Gitlab::Database::BulkUpdate`. This constructs queries such as the
above, and uses binding parameters to avoid SQL injection.

## Usage

To use this, we need:

- the list of columns to update
- a mapping from object/ID to the new values to set for that object
- a way to determine the table for each object

For example, we can express the query above as:

```ruby
issue_a = Issue.find(..)
issue_b = Issue.find(..)

# Issues a single query:
::Gitlab::Database::BulkUpdate.execute(%i[title weight], {
  issue_a => { title: 'Very difficult issue', weight: 8 },
  issue_b => { title: 'Very easy issue', weight: 1 }
})
```

Here the table can be determined automatically, from calling
`object.class.table_name`, so we don't need to provide anything.

We can even pass heterogeneous sets of objects, if the updates all make sense
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

If your objects do not return the correct model class (perhaps because they are
part of a union), then we need to specify this explicitly in a block:

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

Note that this is a **very low level** tool, and operates on the raw column
values. Enumerations and state fields must be translated into their underlying
representations, for example, and nested associations are not supported. No
validations or hooks are called.
