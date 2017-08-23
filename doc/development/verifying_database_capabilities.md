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
