# Merge Request Performance Guidelines

To ensure a merge request does not negatively impact performance of GitLab
_every_ merge request **must** adhere to the guidelines outlined in this
document. There are no exceptions to this rule unless specifically discussed
with and agreed upon by merge request endbosses and performance specialists.

To measure the impact of a merge request you can use
[Sherlock](profiling.md#sherlock). It's also highly recommended that you read
the following guides:

* [Performance Guidelines](performance.md)
* [What requires downtime?](what_requires_downtime.md)

## Impact Analysis

**Summary:** think about the impact your merge request may have on performance
and those maintaining a GitLab setup.

Any change submitted can have an impact not only on the application itself but
also those maintaining it and those keeping it up and running (e.g. production
engineers). As a result you should think carefully about the impact of your
merge request on not only the application but also on the people keeping it up
and running.

Can the queries used potentially take down any critical services and result in
engineers being woken up in the night? Can a malicious user abuse the code to
take down a GitLab instance? Will my changes simply make loading a certain page
slower? Will execution time grow exponentially given enough load or data in the
database?

These are all questions one should ask themselves before submitting a merge
request. It may sometimes be difficult to assess the impact, in which case you
should ask a performance specialist to review your code. See the "Reviewing"
section below for more information.

## Performance Review

**Summary:** ask performance specialists to review your code if you're not sure
about the impact.

Sometimes it's hard to assess the impact of a merge request. In this case you
should ask one of the merge request (mini) endbosses to review your changes. You
can find a list of these endbosses at <https://about.gitlab.com/team/>. An
endboss in turn can request a performance specialist to review the changes.

## Query Counts

**Summary:** a merge request **should not** increase the number of executed SQL
queries unless absolutely necessary.

The number of queries executed by the code modified or added by a merge request
must not increase unless absolutely necessary. When building features it's
entirely possible you will need some extra queries, but you should try to keep
this at a minimum.

As an example, say you introduce a feature that updates a number of database
rows with the same value. It may be very tempting (and easy) to write this using
the following pseudo code:

```ruby
objects_to_update.each do |object|
  object.some_field = some_value
  object.save
end
```

This will end up running one query for every object to update. This code can
easily overload a database given enough rows to update or many instances of this
code running in parallel. This particular problem is known as the
["N+1 query problem"](http://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations).

In this particular case the workaround is fairly easy:

```ruby
objects_to_update.update_all(some_field: some_value)
```

This uses ActiveRecord's `update_all` method to update all rows in a single
query. This in turn makes it much harder for this code to overload a database.

## Executing Queries in Loops

**Summary:** SQL queries **must not** be executed in a loop unless absolutely
necessary.

Executing SQL queries in a loop can result in many queries being executed
depending on the number of iterations in a loop. This may work fine for a
development environment with little data, but in a production environment this
can quickly spiral out of control.

There are some cases where this may be needed. If this is the case this should
be clearly mentioned in the merge request description.

## Eager Loading

**Summary:** always eager load associations when retrieving more than one row.

When retrieving multiple database records for which you need to use any
associations you **must** eager load these associations. For example, if you're
retrieving a list of blog posts and you want to display their authors you
**must** eager load the author associations.

In other words, instead of this:

```ruby
Post.all.each do |post|
  puts post.author.name
end
```

You should use this:

```ruby
Post.all.includes(:author).each do |post|
  puts post.author.name
end
```

## Memory Usage

**Summary:** merge requests **must not** increase memory usage unless absolutely
necessary.

A merge request must not increase the memory usage of GitLab by more than the
absolute bare minimum required by the code. This means that if you have to parse
some large document (e.g. an HTML document) it's best to parse it as a stream
whenever possible, instead of loading the entire input into memory. Sometimes
this isn't possible, in that case this should be stated explicitly in the merge
request.

## Lazy Rendering of UI Elements

**Summary:** only render UI elements when they're actually needed.

Certain UI elements may not always be needed. For example, when hovering over a
diff line there's a small icon displayed that can be used to create a new
comment. Instead of always rendering these kind of elements they should only be
rendered when actually needed. This ensures we don't spend time generating
Haml/HTML when it's not going to be used.

## Instrumenting New Code

**Summary:** always add instrumentation for new classes, modules, and methods.

Newly added classes, modules, and methods must be instrumented. This ensures
we can track the performance of this code over time.

For more information see [Instrumentation](instrumentation.md). This guide
describes how to add instrumentation and where to add it.

## Use of Caching

**Summary:** cache data in memory or in Redis when it's needed multiple times in
a transaction or has to be kept around for a certain time period.

Sometimes certain bits of data have to be re-used in different places during a
transaction. In these cases this data should be cached in memory to remove the
need for running complex operations to fetch the data. You should use Redis if
data should be cached for a certain time period instead of the duration of the
transaction.

For example, say you process multiple snippets of text containiner username
mentions (e.g. `Hello @alice` and `How are you doing @alice?`). By caching the
user objects for every username we can remove the need for running the same
query for every mention of `@alice`.

Caching data per transaction can be done using
[RequestStore](https://github.com/steveklabnik/request_store). Caching data in
Redis can be done using [Rails' caching
system](http://guides.rubyonrails.org/caching_with_rails.html).
