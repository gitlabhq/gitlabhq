---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Serializing Data
---

**Summary:** don't store serialized data in the database, use separate columns
and/or tables instead. This includes storing of comma separated values as a
string.

Rails makes it possible to store serialized data in JSON, YAML or other formats.
Such a field can be defined as follows:

```ruby
class Issue < ActiveRecord::Model
  serialize :custom_fields
end
```

While it may be tempting to store serialized data in the database there are many
problems with this. This document outlines these problems and provide an
alternative.

## Serialized Data Is Less Powerful

When using a relational database you have the ability to query individual
fields, change the schema, index data, and so forth. When you use serialized data
all of that becomes either very difficult or downright impossible. While
PostgreSQL does offer the ability to query JSON fields it is mostly meant for
very specialized use cases, and not for more general use. If you use YAML in
turn there's no way to query the data at all.

## Waste Of Space

Storing serialized data such as JSON or YAML ends up wasting a lot of space.
This is because these formats often include additional characters (for example, double
quotes or newlines) besides the data that you are storing.

## Difficult To Manage

There comes a time where you must add a new field to the serialized
data, or change an existing one. Using serialized data this becomes difficult
and very time consuming as the only way of doing so is to re-write all the
stored values. To do so you would have to:

1. Retrieve the data
1. Parse it into a Ruby structure
1. Mutate it
1. Serialize it back to a String
1. Store it in the database

On the other hand, if one were to use regular columns adding a column would be:

```sql
ALTER TABLE table_name ADD COLUMN column_name type;
```

Such a query would take very little to no time and would immediately apply to
all rows, without having to re-write large JSON or YAML structures.

Finally, there comes a time when the JSON or YAML structure is no longer
sufficient and you must migrate away from it. When storing only a few rows
this may not be a problem, but when storing millions of rows such a migration
can take hours or even days to complete.

## Relational Databases Are Not Document Stores

When storing data as JSON or YAML you're essentially using your database as if
it were a document store (for example, MongoDB), except you're not using any of the
powerful features provided by a typical RDBMS _nor_ are you using any of the
features provided by a typical document store (for example, the ability to index fields
of documents with variable fields). In other words, it's a waste.

## Consistent Fields

One argument sometimes made in favour of serialized data is having to store
widely varying fields and values. Sometimes this is truly the case, and then
perhaps it might make sense to use serialized data. However, in 99% of the cases
the fields and types stored tend to be the same for every row. Even if there is
a slight difference you can still use separate columns and just not set the ones
you don't need.

## The Solution

The solution is to use separate columns and/or separate tables.
This allows you to use all the features provided by your database, it
makes it easier to manage and migrate the data, you conserve space, you can
index the data efficiently and so forth.
