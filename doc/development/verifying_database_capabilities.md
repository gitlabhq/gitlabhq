# Verifying Database Capabilities

Sometimes certain bits of code may only work on a certain database and/or
version. While we try to avoid such code as much as possible sometimes it is
necessary to add database (version) specific behaviour.

To facilitate this we have the following methods that you can use:

* `Gitlab::Database.postgresql?`: returns `true` if PostgreSQL is being used
* `Gitlab::Database.mysql?`: returns `true` if MySQL is being used
* `Gitlab::Database.version`: returns the PostgreSQL version number as a string
  in the format `X.Y.Z`. This method does not work for MySQL

This allows you to write code such as:

```ruby
if Gitlab::Database.postgresql?
  if Gitlab::Database.version.to_f >= 9.6
    run_really_fast_query
  else
    run_fast_query
  end
else
  run_query
end
```

# Read-only database

The database can be used in read-only mode. In this case we have to
make sure all GET requests don't attempt any write operations to the
database. If one of those requests wants to write to the database, it needs
to be wrapped in a `Gitlab::Database.read_only?` or `Gitlab::Database.read_write?`
guard, to make sure it doesn't for read-only databases.

We have a Rails Middleware that filters any potentially writing
operations (the CUD operations of CRUD) and prevent the user from trying
to update the database and getting a 500 error (see `Gitlab::Middleware::ReadOnly`).
