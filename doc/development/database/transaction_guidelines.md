---
stage: Enablement
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Transaction guidelines

This document gives a few examples of the usage of database transactions in application code.

For further reference please check PostgreSQL documentation about [transactions](https://www.postgresql.org/docs/current/tutorial-transactions.html).

## Database decomposition and sharding

The [sharding group](https://about.gitlab.com/handbook/engineering/development/enablement/sharding) plans to split the main GitLab database and move some of the database tables to other database servers.

The group will start decomposing the `ci_*` related database tables first. To maintain the current application development experience, tooling and static analyzers will be added to the codebase to ensure correct data access and data modification methods. By using the correct form for defining database transactions, we can save significant refactoring work in the future.

## The transaction block

The `ActiveRecord` library provides a convenient way to group database statements into a transaction.

```ruby
issue = Issue.find(10)
project = issue.project

ApplicationRecord.transaction do
  issue.update!(title: 'updated title')
  project.update!(last_update_at: Time.now)
end
```

This transaction involves two database tables, in case of an error, each `UPDATE` statement will be rolled back to the previous, consistent state.

NOTE:
Avoid referencing the `ActiveRecord::Base` class and use `ApplicationRecord` instead.

## Transaction and database locks

When a transaction block is opened, the database will try to acquire the necessary locks on the resources. The type of locks will depend on the actual database statements.

Consider a concurrent update scenario where the following code is executed at the same time from two different processes:

```ruby
issue = Issue.find(10)
project = issue.project

ApplicationRecord.transaction do
  issue.update!(title: 'updated title')
  project.update!(last_update_at: Time.now)
end
```

The database will try to acquire the `FOR UPDATE` lock for the referenced `issue` and `project` records. In our case, we have two competing transactions for these locks, one of them will successfully acquire them. The other transaction will have to wait in the lock queue until the first transaction finishes. The execution of the second transaction is blocked at this point.

## Transaction speed

To prevent lock contention and maintain stable application performance, the transaction block should finish as fast as possible. When a transaction acquires locks, it will hold on to them until the transaction finishes.

Apart from application performance, long-running transactions can also affect the application upgrade processes by blocking database migrations.

### Dangerous example: 3rd party API calls

Consider the following example:

```ruby
member = Member.find(5)

Member.transaction do
  member.update!(notification_email_sent: true)

  member.send_notification_email
end
```

Here, we ensure that the `notification_email_sent` column is updated only when the `send_notification_email` method succeeds. The `send_notification_email` method executes a network request to an email sending service. If the underlying infrastructure does not specify timeouts or the network call takes too long time, the database transaction will stay open.

Ideally, a transaction should only contain database statements.

Avoid doing in a `transaction` block:

- External network requests such as: triggering Sidekiq jobs, sending emails, HTTP API calls and running database statements using a different connection.
- File system operations.
- Long, CPU intensive computation.
- Calling `sleep(n)`.

## Explicit model referencing

If a transaction modifies records from the same database table, it's advised to use the `Model.transaction` block:

```ruby
build_1 = Ci::Build.find(1)
build_2 = Ci::Build.find(2)

Ci::Build.transaction do
  build_1.touch
  build_2.touch
end
```

The transaction above will use the same database connection for the transaction as the models in the `transaction` block. In a multi-database environment the following example would be dangerous:

```ruby
# `ci_builds` table is located on another database
class Ci::Build < CiDatabase
end

build_1 = Ci::Build.find(1)
build_2 = Ci::Build.find(2)

ActiveRecord::Base.transaction do
  build_1.touch
  build_2.touch
end
```

The `ActiveRecord::Base` class uses a different database connection than the `Ci::Build` records. The two statements in the transaction block will not be part of the transaction and will not be rolled back in case something goes wrong. They act as 3rd part calls.
