---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Ordering Table Columns in PostgreSQL
---

For GitLab we require that columns of new tables are ordered to use the
least amount of space. An easy way of doing this is to order them based on the
type size in descending order with variable sizes (`text`, `varchar`, arrays,
`json`, `jsonb`, and so on) at the end.

Similar to C structures the space of a table is influenced by the order of
columns. This is because the size of columns is aligned depending on the type of
the following column. Let's consider an example:

- `id` (integer, 4 bytes)
- `name` (text, variable)
- `user_id` (integer, 4 bytes)

The first column is a 4-byte integer. The next is text of variable length. The
`text` data type requires 1-word alignment, and on 64-bit platform, 1 word is 8
bytes. To meet the alignment requirements, four zeros are to be added right
after the first column, so `id` occupies 4 bytes, then 4 bytes of alignment
padding, and only next `name` is being stored. Therefore, in this case, 8 bytes
are spent for storing a 4-byte integer.

The space between rows is also subject to alignment padding. The `user_id`
column takes only 4 bytes, and on 64-bit platform, 4 zeroes are added for
alignment padding, to allow storing the next row beginning with the "clear" word.

As a result, the actual size of each column would be (omitting variable length
data and 24-byte tuple header): 8 bytes, variable, 8 bytes. This means that
each row requires at least 16 bytes for the two 4-byte integers. If a table
has a few rows this is not an issue. However, once you start storing millions of
rows you can save space by using a different order. For the above example, the
ideal column order would be the following:

- `id` (integer, 4 bytes)
- `user_id` (integer, 4 bytes)
- `name` (text, variable)

or

- `name` (text, variable)
- `id` (integer, 4 bytes)
- `user_id` (integer, 4 bytes)

In these examples, the `id` and `user_id` columns are packed together, which
means we only need 8 bytes to store _both_ of them. This in turn means each row
requires 8 bytes less space.

Since Ruby on Rails 5.1, the default data type for IDs is `bigint`, which uses 8 bytes.
We are using `integer` in the examples to showcase a more realistic reordering scenario.

## Type Sizes

While the [PostgreSQL documentation](https://www.postgresql.org/docs/current/datatype.html) contains plenty
of information we list the sizes of common types here so it's easier to
look them up. Here "word" refers to the word size, which is 4 bytes for a 32
bits platform and 8 bytes for a 64 bits platform.

| Type             | Size                                 | Alignment needed |
|:-----------------|:-------------------------------------|:-----------|
| `smallint`         | 2 bytes                              | 1 word     |
| `integer`          | 4 bytes                              | 1 word     |
| `bigint`           | 8 bytes                              | 8 bytes    |
| `real`             | 4 bytes                              | 1 word     |
| `double precision` | 8 bytes                              | 8 bytes    |
| `boolean`          | 1 byte                               | not needed |
| `text` / `string`  | variable, 1 byte plus the data       | 1 word     |
| `bytea`            | variable, 1 or 4 bytes plus the data | 1 word     |
| `timestamp`        | 8 bytes                              | 8 bytes    |
| `timestamptz`      | 8 bytes                              | 8 bytes    |
| `date`             | 4 bytes                              | 1 word     |

A "variable" size means the actual size depends on the value being stored. If
PostgreSQL determines this can be embedded directly into a row it may do so, but
for very large values it stores the data externally and store a pointer (of
1 word in size) in the column. Because of this variable sized columns should
always be at the end of a table.

## Real Example

Let's use the `events` table as an example, which currently has the following
layout:

| Column        | Type                        | Size     |
|:--------------|:----------------------------|:---------|
| `id`          | integer                     | 4 bytes  |
| `target_type` | character varying           | variable |
| `target_id`   | integer                     | 4 bytes  |
| `title`       | character varying           | variable |
| `data`        | text                        | variable |
| `project_id`  | integer                     | 4 bytes  |
| `created_at`  | timestamp without time zone | 8 bytes  |
| `updated_at`  | timestamp without time zone | 8 bytes  |
| `action`      | integer                     | 4 bytes  |
| `author_id`   | integer                     | 4 bytes  |

After adding padding to align the columns this would translate to columns being
divided into fixed size chunks as follows:

| Chunk Size | Columns               |
|:-----------|:----------------------|
| 8 bytes    | `id`                  |
| variable   | `target_type`         |
| 8 bytes    | `target_id`           |
| variable   | `title`               |
| variable   | `data`                |
| 8 bytes    | `project_id`          |
| 8 bytes    | `created_at`          |
| 8 bytes    | `updated_at`          |
| 8 bytes    | `action`, `author_id` |

This means that excluding the variable sized data and tuple header, we need at
least 8 * 6 = 48 bytes per row.

We can optimize this by using the following column order instead:

| Column        | Type                        | Size     |
|:--------------|:----------------------------|:---------|
| `created_at`  | timestamp without time zone | 8 bytes  |
| `updated_at`  | timestamp without time zone | 8 bytes  |
| `id`          | integer                     | 4 bytes  |
| `target_id`   | integer                     | 4 bytes  |
| `project_id`  | integer                     | 4 bytes  |
| `action`      | integer                     | 4 bytes  |
| `author_id`   | integer                     | 4 bytes  |
| `target_type` | character varying           | variable |
| `title`       | character varying           | variable |
| `data`        | text                        | variable |

This would produce the following chunks:

| Chunk Size | Columns                |
|:-----------|:-----------------------|
| 8 bytes    | `created_at`           |
| 8 bytes    | `updated_at`           |
| 8 bytes    | `id`, `target_id`      |
| 8 bytes    | `project_id`, `action` |
| 8 bytes    | `author_id`            |
| variable   | `target_type`          |
| variable   | `title`                |
| variable   | `data`                 |

Here we only need 40 bytes per row excluding the variable sized data and 24-byte
tuple header. 8 bytes being saved may not sound like much, but for tables as
large as the `events` table it does begin to matter. For example, when storing
80 000 000 rows this translates to a space saving of at least 610 MB, all by
just changing the order of a few columns.
