# Database helpers

There are a number of useful helper modules defined in `/lib/gitlab/database/`.

## Subquery

In some cases it is not possible to perform an operation on a query.
For example:

```ruby
Geo::EventLog.where('id < 100').limit(10).delete_all
```

Will give this error:

> ActiveRecord::ActiveRecordError: delete_all doesn't support limit

One solution would be to wrap it in another `where`:

```ruby
Geo::EventLog.where(id: Geo::EventLog.where('id < 100').limit(10)).delete_all
```

This works with PostgreSQL, but with MySQL it gives this error:

> ActiveRecord::StatementInvalid: Mysql2::Error: This version of MySQL
> doesn't yet support 'LIMIT & IN/ALL/ANY/SOME subquery'

Also, that query doesn't have very good performance. Using a
`INNER JOIN` with itself is better.

So instead of this query:

```sql
SELECT geo_event_log.*
FROM geo_event_log
WHERE geo_event_log.id IN
    (SELECT geo_event_log.id
     FROM geo_event_log
     WHERE (id < 100)
     LIMIT 10)
```

It's better to write:

```sql
SELECT geo_event_log.*
FROM geo_event_log
INNER JOIN
  (SELECT geo_event_log.*
   FROM geo_event_log
   WHERE (id < 100)
   LIMIT 10) t2 ON geo_event_log.id = t2.id
```

And this is where `Gitlab::Database::Subquery.self_join` can help
you. So you can rewrite the above statement as:

```ruby
Gitlab::Database::Subquery.self_join(Geo::EventLog.where('id < 100').limit(10)).delete_all
```

And this also works with MySQL, so you don't need to worry about that.
