---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Polymorphic Associations
---

**Summary:** always use separate tables instead of polymorphic associations.

Rails makes it possible to define so called "polymorphic associations". This
usually works by adding two columns to a table: a target type column, and a
target ID. For example, at the time of writing we have such a setup for
`members` with the following columns:

- `source_type`: a string defining the model to use, can be either `Project` or
  `Namespace`.
- `source_id`: the ID of the row to retrieve based on `source_type`. For
  example, when `source_type` is `Project` then `source_id` contains a
  project ID.

While such a setup may appear to be useful, it comes with many drawbacks; enough
that you should avoid this at all costs.

## Space Wasted

Because this setup relies on string values to determine the model to use, it
wastes a lot of space. For example, for `Project` and `Namespace` the
maximum size is 9 bytes, plus 1 extra byte for every string when using
PostgreSQL. While this may only be 10 bytes per row, given enough tables and
rows using such a setup we can end up wasting quite a bit of disk space and
memory (for any indexes).

## Indexes

Because our associations are broken up into two columns this may result in
requiring composite indexes for queries to be performed efficiently. While
composite indexes are not wrong at all, they can be tricky to set up as the
ordering of columns in these indexes is important to ensure optimal performance.

## Consistency

One really big problem with polymorphic associations is being unable to enforce
data consistency on the database level using foreign keys. For consistency to be
enforced on the database level one would have to write their own foreign key
logic to support polymorphic associations.

Enforcing consistency on the database level is absolutely crucial for
maintaining a healthy environment, and thus is another reason to avoid
polymorphic associations.

## Query Overhead

When using polymorphic associations you always need to filter using both
columns. For example, you may end up writing a query like this:

```sql
SELECT *
FROM members
WHERE source_type = 'Project'
AND source_id = 13083;
```

Here PostgreSQL can perform the query quite efficiently if both columns are
indexed. As the query gets more complex, it may not be able to use these
indexes effectively.

## Mixed Responsibilities

Similar to functions and classes, a table should have a single responsibility:
storing data with a certain set of pre-defined columns. When using polymorphic
associations, you are storing different types of data (possibly with
different columns set) in the same table.

## The Solution

Fortunately, there is a solution to these problems: use a
separate table for every type you would otherwise store in the same table. Using
a separate table allows you to use everything a database may provide to ensure
consistency and query data efficiently, without any additional application logic
being necessary.

Let's say you have a `members` table storing both approved and pending members,
for both projects and groups, and the pending state is determined by the column
`requested_at` being set or not. Schema wise such a setup can lead to various
columns only being set for certain rows, wasting space. It's also possible that
certain indexes are only set for certain rows, again wasting space. Finally,
querying such a table requires less than ideal queries. For example:

```sql
SELECT *
FROM members
WHERE requested_at IS NULL
AND source_type = 'GroupMember'
AND source_id = 4
```

Instead such a table should be broken up into separate tables. For example, you
may end up with 4 tables in this case:

- `project_members`
- `group_members`
- `pending_project_members`
- `pending_group_members`

This makes querying data trivial. For example, to get the members of a group
you'd run:

```sql
SELECT *
FROM group_members
WHERE group_id = 4
```

To get all the pending members of a group in turn you'd run:

```sql
SELECT *
FROM pending_group_members
WHERE group_id = 4
```

If you want to get both you can use a `UNION`, though you need to be explicit
about what columns you want to `SELECT` as otherwise the result set uses the
columns of the first query. For example:

```sql
SELECT id, 'Group' AS target_type, group_id AS target_id
FROM group_members

UNION ALL

SELECT id, 'Project' AS target_type, project_id AS target_id
FROM project_members
```

The above example is perhaps a bit silly, but it shows that there's nothing
stopping you from merging the data together and presenting it on the same page.
Selecting columns explicitly can also speed up queries as the database has to do
less work to get the data (compared to selecting all columns, even ones you're
not using).

Our schema also becomes easier. No longer do we need to both store and index the
`source_type` column, we can define foreign keys easily, and we don't need to
filter rows using the `IS NULL` condition.

To summarize: using separate tables allows us to use foreign keys effectively,
create indexes only where necessary, conserve space, query data more
efficiently, and scale these tables more easily (for example, by storing them on
separate disks). A nice side effect of this is that code can also become easier,
as a single model isn't responsible for handling different kinds of
data.
