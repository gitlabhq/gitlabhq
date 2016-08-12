# Performance Guidelines

This document describes various guidelines to follow to ensure good and
consistent performance of GitLab.

## Workflow

The process of solving performance problems is roughly as follows:

1. Make sure there's an issue open somewhere (e.g., on the GitLab CE issue
   tracker), create one if there isn't. See [#15607][#15607] for an example.
2. Measure the performance of the code in a production environment such as
   GitLab.com (see the [Tooling](#tooling) section below). Performance should be
   measured over a period of _at least_ 24 hours.
3. Add your findings based on the measurement period (screenshots of graphs,
   timings, etc) to the issue mentioned in step 1.
4. Solve the problem.
5. Create a merge request, assign the "Performance" label and assign it to
   [@yorickpeterse][yorickpeterse] for reviewing.
6. Once a change has been deployed make sure to _again_ measure for at least 24
   hours to see if your changes have any impact on the production environment.
7. Repeat until you're done.

When providing timings make sure to provide:

* The 95th percentile
* The 99th percentile
* The mean

When providing screenshots of graphs, make sure that both the X and Y axes and
the legend are clearly visible. If you happen to have access to GitLab.com's own
monitoring tools you should also provide a link to any relevant
graphs/dashboards.

## Tooling

GitLab provides two built-in tools to aid the process of improving performance:

* [Sherlock](profiling.md#sherlock)
* [GitLab Performance Monitoring](../monitoring/performance/monitoring.md)

GitLab employees can use GitLab.com's performance monitoring systems located at
<http://performance.gitlab.net>, this requires you to log in using your
`@gitlab.com` Email address. Non-GitLab employees are advised to set up their
own InfluxDB + Grafana stack.

## Benchmarks

Benchmarks are almost always useless. Benchmarks usually only test small bits of
code in isolation and often only measure the best case scenario. On top of that,
benchmarks for libraries (e.g., a Gem) tend to be biased in favour of the
library. After all there's little benefit to an author publishing a benchmark
that shows they perform worse than their competitors.

Benchmarks are only really useful when you need a rough (emphasis on "rough")
understanding of the impact of your changes. For example, if a certain method is
slow a benchmark can be used to see if the changes you're making have any impact
on the method's performance. However, even when a benchmark shows your changes
improve performance there's no guarantee the performance also improves in a
production environment.

When writing benchmarks you should almost always use
[benchmark-ips](https://github.com/evanphx/benchmark-ips). Ruby's `Benchmark`
module that comes with the standard library is rarely useful as it runs either a
single iteration (when using `Benchmark.bm`) or two iterations (when using
`Benchmark.bmbm`). Running this few iterations means external factors (e.g. a
video streaming in the background) can very easily skew the benchmark
statistics.

Another problem with the `Benchmark` module is that it displays timings, not
iterations. This means that if a piece of code completes in a very short period
of time it can be very difficult to compare the timings before and after a
certain change. This in turn leads to patterns such as the following:

```ruby
Benchmark.bmbm(10) do |bench|
  bench.report 'do something' do
    100.times do
      ... work here ...
    end
  end
end
```

This however leads to the question: how many iterations should we run to get
meaningful statistics?

The benchmark-ips Gem basically takes care of all this and much more, and as a
result of this should be used instead of the `Benchmark` module.

In short:

1. Don't trust benchmarks you find on the internet.
2. Never make claims based on just benchmarks, always measure in production to
   confirm your findings.
3. X being N times faster than Y is meaningless if you don't know what impact it
   will actually have on your production environment.
4. A production environment is the _only_ benchmark that always tells the truth
   (unless your performance monitoring systems are not set up correctly).
5. If you must write a benchmark use the benchmark-ips Gem instead of Ruby's
   `Benchmark` module.

## Importance of Changes

When working on performance improvements, it's important to always ask yourself
the question "How important is it to improve the performance of this piece of
code?". Not every piece of code is equally important and it would be a waste to
spend a week trying to improve something that only impacts a tiny fraction of
our users. For example, spending a week trying to squeeze 10 milliseconds out of
a method is a waste of time when you could have spent a week squeezing out 10
seconds elsewhere.

There is no clear set of steps that you can follow to determine if a certain
piece of code is worth optimizing. The only two things you can do are:

1. Think about what the code does, how it's used, how many times it's called and
   how much time is spent in it relative to the total execution time (e.g., the
   total time spent in a web request).
2. Ask others (preferably in the form of an issue).

Some examples of changes that aren't really important/worth the effort:

* Replacing double quotes with single quotes.
* Replacing usage of Array with Set when the list of values is very small.
* Replacing library A with library B when both only take up 0.1% of the total
  execution time.
* Calling `freeze` on every string (see [String Freezing](#string-freezing)).

## Slow Operations & Sidekiq

Slow operations (e.g. merging branches) or operations that are prone to errors
(using external APIs) should be performed in a Sidekiq worker instead of
directly in a web request as much as possible. This has numerous benefits such
as:

1. An error won't prevent the request from completing.
2. The process being slow won't affect the loading time of a page.
3. In case of a failure it's easy to re-try the process (Sidekiq takes care of
   this automatically).
4. By isolating the code from a web request it will hopefully be easier to test
   and maintain.

It's especially important to use Sidekiq as much as possible when dealing with
Git operations as these operations can take quite some time to complete
depending on the performance of the underlying storage system.

## Git Operations

Care should be taken to not run unnecessary Git operations. For example,
retrieving the list of branch names using `Repository#branch_names` can be done
without an explicit check if a repository exists or not. In other words, instead
of this:

```ruby
if repository.exists?
  repository.branch_names.each do |name|
    ...
  end
end
```

You can just write:

```ruby
repository.branch_names.each do |name|
  ...
end
```

## Caching

Operations that will often return the same result should be cached using Redis,
in particular Git operations. When caching data in Redis, make sure the cache is
flushed whenever needed. For example, a cache for the list of tags should be
flushed whenever a new tag is pushed or a tag is removed.

When adding cache expiration code for repositories, this code should be placed
in one of the before/after hooks residing in the Repository class. For example,
if a cache should be flushed after importing a repository this code should be
added to `Repository#after_import`. This ensures the cache logic stays within
the Repository class instead of leaking into other classes.

When caching data, make sure to also memoize the result in an instance variable.
While retrieving data from Redis is much faster than raw Git operations, it still
has overhead. By caching the result in an instance variable, repeated calls to
the same method won't end up retrieving data from Redis upon every call. When
memoizing cached data in an instance variable, make sure to also reset the
instance variable when flushing the cache. An example:


```ruby
def first_branch
  @first_branch ||= cache.fetch(:first_branch) { branches.first }
end

def expire_first_branch_cache
  cache.expire(:first_branch)
  @first_branch = nil
end
```

## Anti-Patterns

This is a collection of [anti-patterns][anti-pattern] that should be avoided
unless these changes have a measurable, significant and positive impact on
production environments.

### String Freezing

In recent Ruby versions calling `freeze` on a String leads to it being allocated
only once and re-used. For example, on Ruby 2.3 this will only allocate the
"foo" String once:

```ruby
10.times do
  'foo'.freeze
end
```

Blindly adding a `.freeze` call to every String is an anti-pattern that should
be avoided unless one can prove (using production data) the call actually has a
positive impact on performance.

This feature of Ruby wasn't really meant to make things faster directly, instead
it was meant to reduce the number of allocations. Depending on the size of the
String and how frequently it would be allocated (before the `.freeze` call was
added), this _may_ make things faster, but there's no guarantee it will.

Another common flavour of this is to not only freeze a String, but also assign
it to a constant, for example:

```ruby
SOME_CONSTANT = 'foo'.freeze

9000.times do
  SOME_CONSTANT
end
```

The only reason you should be doing this is to prevent somebody from mutating
the global String. However, since you can just re-assign constants in Ruby
there's nothing stopping somebody from doing this elsewhere in the code:

```ruby
SOME_CONSTANT = 'bar'
```

### Moving Allocations to Constants

Storing an object as a constant so you only allocate it once _may_ improve
performance, but there's no guarantee this will. Looking up constants has an
impact on runtime performance, and as such, using a constant instead of
referencing an object directly may even slow code down.

[#15607]: https://gitlab.com/gitlab-org/gitlab-ce/issues/15607
[yorickpeterse]: https://gitlab.com/u/yorickpeterse
[anti-pattern]: https://en.wikipedia.org/wiki/Anti-pattern
