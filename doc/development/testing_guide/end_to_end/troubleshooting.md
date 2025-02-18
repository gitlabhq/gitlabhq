---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Troubleshooting end-to-end tests
---

## See what the browser is doing

If end-to-end tests fail, it can be very helpful to see what is happening in your
browser when it fails. For example, if tests don't run at all, the test framework
might be trying to open a URL that isn't valid on your machine. This problem becomes
clearer if you see the page fail in the browser.

To make the test framework show the browser as it runs the tests,
set `WEBDRIVER_HEADLESS=false`. For example:

```shell
cd gitlab/qa
WEBDRIVER_HEADLESS=false bundle exec bin/qa Test::Instance::All http://localhost:3000
```

## Enable logging

Sometimes a test might fail and the failure stack trace doesn't provide enough
information to determine what went wrong. You can get more information by enabling
debug logs by setting `QA_LOG_LEVEL=debug`, to see what the test framework is attempting.
For example:

```shell
cd gitlab/qa
QA_LOG_LEVEL=debug bundle exec bin/qa Test::Instance::All http://localhost:3000
```

The test framework then outputs many logs showing the actions taken during
the tests:

```plaintext
[date=2022-03-31 23:19:47 from=QA Tests] INFO  -- Starting test: Create Merge request creation from fork can merge feature branch fork to mainline
[date=2022-03-31 23:19:49 from=QA Tests] DEBUG -- has_element? :login_page (wait: 0) returned: true
[date=2022-03-31 23:19:52 from=QA Tests] DEBUG -- filling :login_field with "root"
[date=2022-03-31 23:19:52 from=QA Tests] DEBUG -- filling :password_field with "*****"
[date=2022-03-31 23:19:52 from=QA Tests] DEBUG -- clicking :sign_in_button
```

## Tests don't run at all

This section assumes you're running the tests locally (such as the GDK) and you're doing
so from the `gitlab/qa/` folder, not from `gitlab-qa`. For example, if you receive a
`Net::ReadTimeout` error, the browser might be unable to load the specified URL:

```shell
cd gitlab/qa
bundle exec bin/qa Test::Instance::All http://localhost:3000

bundler: failed to load command: bin/qa (bin/qa)
Net::ReadTimeout: Net::ReadTimeout with #<TCPSocket:(closed)>
```

This error can happen if GitLab runs on an address that does not resolve from
`localhost`. For example, if you set the GDK `hostname`
[to a specific local IP address](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/run_qa_against_gdk.md#run-qa-tests-against-your-gdk-setup),
you must use that IP address instead of `localhost` in the command.
For example, if your IP is `192.168.0.12`:

```shell
bundle exec bin/qa Test::Instance::All http://192.168.0.12:3000
```
