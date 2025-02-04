---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Transaction guidelines
---

This document gives a few examples of the usage of database transactions in application code.

For further reference, check PostgreSQL documentation about [transactions](https://www.postgresql.org/docs/current/tutorial-transactions.html).

## Database decomposition and sharding

The [Pods group](https://handbook.gitlab.com/handbook/engineering/infrastructure/core-platform/data_stores/tenant-scale/) plans
to split the main GitLab database and move some of the database tables to other database servers.

We start decomposing the `ci_*`-related database tables first. To maintain the current application
development experience, we add tooling and static analyzers to the codebase to ensure correct
data access and data modification methods. By using the correct form for defining database transactions,
we can save significant refactoring work in the future.

## The transaction block

The `ActiveRecord` library provides a convenient way to group database statements into a transaction:

```ruby
issue = Issue.find(10)
project = issue.project

ApplicationRecord.transaction do
  issue.update!(title: 'updated title')
  project.update!(last_update_at: Time.now)
end
```

This transaction involves two database tables. In case of an error, each `UPDATE`
statement rolls back to the previous consistent state.

NOTE:
Avoid referencing the `ActiveRecord::Base` class and use `ApplicationRecord` instead.

## Transaction and database locks

When a transaction block is opened, the database tries to acquire the necessary
locks on the resources. The type of locks depend on the actual database statements.

Consider a concurrent update scenario where the following code is executed at the
same time from two different processes:

```ruby
issue = Issue.find(10)
project = issue.project

ApplicationRecord.transaction do
  issue.update!(title: 'updated title')
  project.update!(last_update_at: Time.now)
end
```

The database tries to acquire the `FOR UPDATE` lock for the referenced `issue` and
`project` records. In our case, we have two competing transactions for these locks,
and only one of them successfully acquires them. The other transaction has
to wait in the lock queue until the first transaction finishes. The execution of the
second transaction is blocked at this point.

## Transaction speed

To prevent lock contention and maintain stable application performance, the transaction
block should finish as fast as possible. When a transaction acquires locks, it holds
on to them until the transaction finishes.

Apart from application performance, long-running transactions can also affect application
upgrade processes by blocking database migrations.

### Dangerous example: third-party API calls

Consider the following example:

```ruby
member = Member.find(5)

Member.transaction do
  member.update!(notification_email_sent: true)

  member.send_notification_email
end
```

Here, we ensure that the `notification_email_sent` column is updated only when the
`send_notification_email` method succeeds. The `send_notification_email` method
executes a network request to an email sending service. If the underlying infrastructure
does not specify timeouts or the network call takes too long time, the database transaction
stays open.

Ideally, a transaction should only contain database statements.

Avoid doing in a `transaction` block:

- External network requests such as:
  - Triggering Sidekiq jobs.
  - Sending emails.
  - HTTP API calls.
  - Running database statements using a different connection.
- File system operations.
- Long, CPU intensive computation.
- Calling `sleep(n)`.

## Explicit model referencing

If a transaction modifies records from the same database table, we advise to use the
`Model.transaction` block:

```ruby
build_1 = Ci::Build.find(1)
build_2 = Ci::Build.find(2)

Ci::Build.transaction do
  build_1.touch
  build_2.touch
end
```

The transaction above uses the same database connection for the transaction as the models
in the `transaction` block. In a multi-database environment the following example is dangerous:

```ruby
# `ci_builds` table is located on another database
class Ci::Build < CiDatabase
end

build_1 = Ci::Build.find(1)
build_2 = Ci::Build.find(2)

ApplicationRecord.transaction do
  build_1.touch
  build_2.touch
end
```

The `ApplicationRecord` class uses a different database connection than the `Ci::Build` records.
The two statements in the transaction block are not part of the transaction and are not
rolled back in case something goes wrong. They act as third-party calls.
