---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
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

- `max`    : Specifies the max amount of *seconds* to wait until the block given is satisfied
- `time`   : The interval/poll time to sleep *in seconds*. If this time reaches `max`, the wait returns `false`
- `reload` : If the wait is not satiated, the test will sleep then reload the page if `:reload` is set to `true`
