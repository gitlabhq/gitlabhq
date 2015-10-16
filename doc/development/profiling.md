# Profiling

To make it easier to track down performance problems GitLab comes with a set of
profiling tools, some of these are available by default while others need to be
explicitly enabled.

## rack-mini-profiler

This Gem is enabled by default in development only. It allows you to see the
timings of the various components that made up a web request (e.g. the SQL
queries executed and their execution timings).

## Bullet

Bullet is a Gem that can be used to track down N+1 query problems. Because
Bullet adds quite a bit of logging noise it's disabled by default. To enable
Bullet, set the environment variable `ENABLE_BULLET` to a non-empty value before
starting GitLab. For example:

    ENABLE_BULLET=true bundle exec rails s

Bullet will log query problems to both the Rails log as well as the Chrome
console.

## ActiveRecord Query Trace

This Gem adds backtraces for every ActiveRecord query in the Rails console. This
can be useful to track down where a query was executed. Because this Gem adds
quite a bit of noise (5-10 extra lines per ActiveRecord query) it's disabled by
default. To use this Gem you'll need to set `ENABLE_QUERY_TRACE` to a non empty
file before starting GitLab. For example:

    ENABLE_QUERY_TRACE=true bundle exec rails s

## rack-lineprof

This is a Gem that can trace the execution time of code on a per line basis.
Because this Gem can add quite a bit of overhead it's disabled by default. To
enable it, set the environment variable `ENABLE_LINEPROF` to a non-empty value.
For example:

    ENABLE_LINEPROF=true bundle exec rails s

Once enabled you'll need to add a query string parameter to a request to
actually profile code execution. The name of the parameter is `lineprof` and
should be set to a regular expression (minus the starting/ending slash) used to
select what files to profile. To profile all files containing "foo" somewhere in
the path you'd use the following parameter:

    ?lineprof=foo

Or when filtering for files containing "foo" and "bar" in their path:

    ?lineprof=foo|bar

Once set the profiling output will be displayed in your terminal.
