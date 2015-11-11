# Profiling

To make it easier to track down performance problems GitLab comes with a set of
profiling tools, some of these are available by default while others need to be
explicitly enabled.

## Sherlock

Sherlock is a custom profiling tool built into GitLab. Sherlock is _only_
available when running GitLab in development mode _and_ when setting the
environment variable `ENABLE_SHERLOCK` to a non empty value. For example:

    ENABLE_SHERLOCK=1 bundle exec rails s

Recorded transactions can be found by navigating to `/sherlock/transactions`.

## Bullet

Bullet is a Gem that can be used to track down N+1 query problems. Because
Bullet adds quite a bit of logging noise it's disabled by default. To enable
Bullet, set the environment variable `ENABLE_BULLET` to a non-empty value before
starting GitLab. For example:

    ENABLE_BULLET=true bundle exec rails s

Bullet will log query problems to both the Rails log as well as the Chrome
console.
