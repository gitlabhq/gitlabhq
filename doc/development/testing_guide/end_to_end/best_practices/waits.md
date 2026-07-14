---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Waits
---

All Capybara Node Finders utilize a waiting mechanism.

Per the [Capybara API](https://www.rubydoc.info/github/jnicklas/capybara/Capybara/Node/Finders:find) -

> If the driver is capable of executing JavaScript, `find` will wait for a set amount of time and continuously retry finding the element until either the element is found or the time expires. The length of time find will wait is controlled through `Capybara.default_max_wait_time` and defaults to `2` seconds. `find` takes the same options as all.

Ideally the [GitLab QA Framework](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/qa) should implement its own explicit waiting to avoid hard sleeps but currently that is [not the case](https://gitlab.com/gitlab-org/gitlab-qa/issues/280).

## Hard Sleeps

**[qa/qa/page/base.rb](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/qa/qa/page/base.rb#L16)**

```ruby
def wait(max: 60, time: 0.1, reload: true)
  ...
end
```

- `max`: Specifies the max amount of seconds to wait until the block given is satisfied
- `time`: The interval/poll time to sleep *in seconds*. If this time reaches `max`, the wait returns `false`
- `reload`: If the wait is not satiated, the test will sleep then reload the page if `:reload` is set to `true`

## Wait for readiness explicitly

A page action often returns before the backend finishes the work it triggered. When a test reads
state in this gap, the result depends on timing, which makes the test flaky. To avoid this, wait for
a signal that confirms the work is complete before you act on a resource or assert against it.

The framework provides several helpers that poll for a condition instead of guessing how long to
wait. For example, `Support::Retrier` and `Support::Waiter` retry an operation until it succeeds, and
resources expose readiness checks such as `runner.wait_until_online`:

```ruby
# Wait until the runner reports itself online before the test depends on it.
runner.wait_until_online
```

Choose a signal that reflects the work you are waiting for, such as a visible element, a resource
state, or an API response. A fixed `sleep` is not a reliable signal because the work can take longer
than the chosen duration, so avoid using one to wait for readiness.

When a wait still times out, first confirm that it waits on the correct signal. Fixing the signal is
more reliable than increasing the timeout, and both are preferable to quarantining the test.
