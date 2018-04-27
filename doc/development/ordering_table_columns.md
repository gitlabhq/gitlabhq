# Ordering Table Columns

Similar to C structures the space of a table is influenced by the order of
columns. This is because the size of columns is aligned depending on the type of
the column. Take the following column order for example:

* id (integer, 4 bytes)
* name (text, variable)
* user_id (integer, 4 bytes)

Integers are aligned to the word size. This means that on a 64 bit platform the
actual size of each column would be: 8 bytes, variable, 8 bytes. This means that
each row will require at least 16 bytes for the two integers, and a variable
amount for the text field. If a table has a few rows this is not an issue, but
once you start storing millions of rows you can save space by using a different
order. For the above example a more ideal column order would be the following:

* id (integer, 4 bytes)
* user_id (integer, 4 bytes)
* name (text, variable)

In this setup the `id` and `user_id` columns can be packed together, which means
we only need 8 bytes to store _both_ of them. This in turn each row will require
8 bytes less of space.

For GitLab we require that columns of new tables are ordered based to use the
least amount of space. An easy way of doing this is to order them based on the
type size in descending order with variable sizes (string and text columns for
example) at the end.

## Type Sizes

While the PostgreSQL documentation
(https://www.postgresql.org/docs/current/static/datatype.html) contains plenty
of information we will list the sizes of common types here so it's easier to
look them up. Here "word" refers to the word size, which is 4 bytes for a 32
bits platform and 8 bytes for a 64 bits platform.

| Type             | Size                                 | Aligned To |
|:-----------------|:-------------------------------------|:-----------|
| smallint         | 2 bytes                              | 1 word     |
| integer          | 4 bytes                              | 1 word     |
| bigint           | 8 bytes                              | 8 bytes    |
| real             | 4 bytes                              | 1 word     |
| double precision | 8 bytes                              | 8 bytes    |
| boolean          | 1 byte                               | not needed |
| text / string    | variable, 1 byte plus the data       | 1 word     |
| bytea            | variable, 1 or 4 bytes plus the data | 1 word     |
| timestamp        | 8 bytes                              | 8 bytes    |
| timestamptz      | 8 bytes                              | 8 bytes    |
| date             | 4 bytes                              | 1 word     |

A "variable" size means the actual size depends on the value being stored. If
PostgreSQL determines this can be embedded directly into a row it may do so, but
for very large values it will store the data externally and store a pointer (of
1 word in size) in the column. Because of this variable sized columns should
always be at the end of a table.

## Real Example

Let's use the "events" table as an example, which currently has the following
layout:

| Column      | Type                        | Size     |
|:------------|:----------------------------|:---------|
| id          | integer                     | 4 bytes  |
| target_type | character varying           | variable |
| target_id   | integer                     | 4 bytes  |
| title       | character varying           | variable |
| data        | text                        | variable |
| project_id  | integer                     | 4 bytes  |
| created_at  | timestamp without time zone | 8 bytes  |
| updated_at  | timestamp without time zone | 8 bytes  |
| action      | integer                     | 4 bytes  |
| author_id   | integer                     | 4 bytes  |

After adding padding to align the columns this would translate to columns being
divided into fixed size chunks as follows:

| Chunk Size | Columns           |
|:-----------|:------------------|
| 8 bytes    | id                |
| variable   | target_type       |
| 8 bytes    | target_id         |
| variable   | title             |
| variable   | data              |
| 8 bytes    | project_id        |
| 8 bytes    | created_at        |
| 8 bytes    | updated_at        |
| 8 bytes    | action, author_id |

This means that excluding the variable sized data we need at least 48 bytes per
row.

We can optimise this by using the following column order instead:

| Column      | Type                        | Size     |
|:------------|:----------------------------|:---------|
| created_at  | timestamp without time zone | 8 bytes  |
| updated_at  | timestamp without time zone | 8 bytes  |
| id          | integer                     | 4 bytes  |
| target_id   | integer                     | 4 bytes  |
| project_id  | integer                     | 4 bytes  |
| action      | integer                     | 4 bytes  |
| author_id   | integer                     | 4 bytes  |
| target_type | character varying           | variable |
| title       | character varying           | variable |
| data        | text                        | variable |

This would produce the following chunks:

| Chunk Size | Columns            |
|:-----------|:-------------------|
| 8 bytes    | created_at         |
| 8 bytes    | updated_at         |
| 8 bytes    | id, target_id      |
| 8 bytes    | project_id, action |
| 8 bytes    | author_id          |
| variable   | target_type        |
| variable   | title              |
| variable   | data               |

Here we only need 40 bytes per row excluding the variable sized data. 8 bytes
being saved may not sound like much, but for tables as large as the "events"
table it does begin to matter. For example, when storing 80 000 000 rows this
translates to a space saving of at least 610 MB: all by just changing the order
of a few columns.
