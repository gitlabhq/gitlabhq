---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Storing SHA1 Hashes As Binary
---

Storing SHA1 hashes as strings is not very space efficient. A SHA1 as a string
requires at least 40 bytes, an additional byte to store the encoding, and
perhaps more space depending on the internals of PostgreSQL.

On the other hand, if one were to store a SHA1 as binary one would only need 20
bytes for the actual SHA1, and 1 or 4 bytes of additional space (again depending
on database internals). This means that in the best case scenario we can reduce
the space usage by 50%.

To make this easier to work with you can include the concern `ShaAttribute` into
a model and define a SHA attribute using the `sha_attribute` class method. For
example:

```ruby
class Commit < ActiveRecord::Base
  include ShaAttribute

  sha_attribute :sha
end
```

This allows you to use the value of the `sha` attribute as if it were a string,
while storing it as binary. This means that you can do something like this,
without having to worry about converting data to the right binary format:

```ruby
commit = Commit.find_by(sha: '88c60307bd1f215095834f09a1a5cb18701ac8ad')
commit.sha = '971604de4cfa324d91c41650fabc129420c8d1cc'
commit.save
```

There is however one requirement: the column used to store the SHA has _must_ be
a binary type. For Rails this means you need to use the `:binary` type instead
of `:text` or `:string`.
