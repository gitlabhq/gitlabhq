# Profiling

To make it easier to track down performance problems GitLab comes with a set of
profiling tools, some of these are available by default while others need to be
explicitly enabled.

## Profiling a URL

There is a `Gitlab::Profiler.profile` method, and corresponding
`bin/profile-url` script, that enable profiling a GET or POST request to a
specific URL, either as an anonymous user (the default) or as a specific user.

When using the script, command-line documentation is available by passing no
arguments.

When using the method in an interactive console session, any changes to the
application code within that console session will be reflected in the profiler
output.

For example:

```ruby
Gitlab::Profiler.profile('/my-user')
# Returns a RubyProf::Profile for the regular operation of this request
class UsersController; def show; sleep 100; end; end
Gitlab::Profiler.profile('/my-user')
# Returns a RubyProf::Profile where 100 seconds is spent in UsersController#show
```

For routes that require authorization you will need to provide a user to
`Gitlab::Profiler`. You can do this like so:

```ruby
Gitlab::Profiler.profile('/gitlab-org/gitlab-test', user: User.first)
```

The user you provide will need to have a [personal access
token](https://docs.gitlab.com/ce/user/profile/personal_access_tokens.html) in
the GitLab instance.

Passing a `logger:` keyword argument to `Gitlab::Profiler.profile` will send
ActiveRecord and ActionController log output to that logger. Further options are
documented with the method source.

There is also a RubyProf printer available:
`Gitlab::Profiler::TotalTimeFlatPrinter`. This acts like
`RubyProf::FlatPrinter`, but its `min_percent` option works on the method's
total time, not its self time. (This is because we often spend most of our time
in library code, but this comes from calls in our application.) It also offers a
`max_percent` option to help filter out outer calls that aren't useful (like
`ActionDispatch::Integration::Session#process`).

There is a convenience method for using this,
`Gitlab::Profiler.print_by_total_time`:

```ruby
result = Gitlab::Profiler.profile('/my-user')
Gitlab::Profiler.print_by_total_time(result, max_percent: 60, min_percent: 2)
# Measure Mode: wall_time
# Thread ID: 70005223698240
# Fiber ID: 70004894952580
# Total: 1.768912
# Sort by: total_time
#
#  %self      total      self      wait     child     calls  name
#   0.00      1.017     0.000     0.000     1.017       14  *ActionView::Helpers::RenderingHelper#render
#   0.00      1.017     0.000     0.000     1.017       14  *ActionView::Renderer#render_partial
#   0.00      1.017     0.000     0.000     1.017       14  *ActionView::PartialRenderer#render
#   0.00      1.007     0.000     0.000     1.007       14  *ActionView::PartialRenderer#render_partial
#   0.00      0.930     0.000     0.000     0.930       14   Hamlit::TemplateHandler#call
#   0.00      0.928     0.000     0.000     0.928       14   Temple::Engine#call
#   0.02      0.865     0.000     0.000     0.864      638  *Enumerable#inject
```

[GitLab-Profiler](https://gitlab.com/gitlab-com/gitlab-profiler) is a project
that builds on this to add some additional niceties, such as allowing
configuration with a single Yaml file for multiple URLs, and uploading of the
profile and log output to S3.

For GitLab.com, you can find the latest results here:
<http://redash.gitlab.com/dashboard/gitlab-profiler-statistics>

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

As a follow up to finding `N+1` queries with Bullet, consider writing a [QueryRecoder test](query_recorder.md) to prevent a regression.
