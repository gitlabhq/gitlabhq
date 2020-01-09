# Flaky tests

## What's a flaky test?

It's a test that sometimes fails, but if you retry it enough times, it passes,
eventually.

## Quarantined tests

When a test frequently fails in `master`,
[a ~"master:broken" issue](https://about.gitlab.com/handbook/engineering/workflow/#broken-master)
should be created.
If the test cannot be fixed in a timely fashion, there is an impact on the
productivity of all the developers, so it should be placed in quarantine by
assigning the `:quarantine` metadata.

This means it will be skipped unless run with `--tag quarantine`:

```shell
bin/rspec --tag quarantine
```

**Before putting a test in quarantine, you should make sure that a
~"master:broken" issue exists for it so it won't stay in quarantine forever.**

Once a test is in quarantine, there are 3 choices:

- Should the test be fixed (i.e. get rid of its flakiness)?
- Should the test be moved to a lower level of testing?
- Should the test be removed entirely (e.g. because there's already a
  lower-level test, or it's duplicating another same-level test, or it's testing
  too much etc.)?

### Quarantine tests on the CI

Quarantined tests are run on the CI in dedicated jobs that are allowed to fail:

- `rspec-pg-quarantine` (CE & EE)
- `rspec-pg-quarantine-ee` (EE only)

## Automatic retries and flaky tests detection

On our CI, we use [rspec-retry] to automatically retry a failing example a few
times (see [`spec/spec_helper.rb`] for the precise retries count).

We also use a home-made `RspecFlaky::Listener` listener which records flaky
examples in a JSON report file on `master` (`retrieve-tests-metadata` and `update-tests-metadata` jobs), and warns when a new flaky example
is detected in any other branch (`flaky-examples-check` job). In the future, the
`flaky-examples-check` job will not be allowed to fail.

This was originally implemented in: <https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/13021>.

[rspec-retry]: https://github.com/NoRedInk/rspec-retry
[`spec/spec_helper.rb`]: https://gitlab.com/gitlab-org/gitlab/blob/master/spec/spec_helper.rb

## Problems we had in the past at GitLab

- [`rspec-retry` is bitting us when some API specs fail](https://gitlab.com/gitlab-org/gitlab-foss/issues/29242): <https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/9825>
- [Sporadic RSpec failures due to `PG::UniqueViolation`](https://gitlab.com/gitlab-org/gitlab-foss/issues/28307#note_24958837): <https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/9846>
  - Follow-up: <https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/10688>
  - [Capybara.reset_session! should be called before requests are blocked](https://gitlab.com/gitlab-org/gitlab-foss/issues/33779): <https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/12224>
- FFaker generates funky data that tests are not ready to handle (and tests should be predictable so that's bad!):
  - [Make `spec/mailers/notify_spec.rb` more robust](https://gitlab.com/gitlab-org/gitlab-foss/issues/20121): <https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/10015>
  - [Transient failure in `spec/requests/api/commits_spec.rb`](https://gitlab.com/gitlab-org/gitlab-foss/issues/27988#note_25342521): <https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/9944>
  - [Replace FFaker factory data with sequences](https://gitlab.com/gitlab-org/gitlab-foss/issues/29643): <https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/10184>
  - [Transient failure in spec/finders/issues_finder_spec.rb](https://gitlab.com/gitlab-org/gitlab-foss/issues/30211#note_26707685): <https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/10404>

### Time-sensitive flaky tests

- <https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/10046>
- <https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/10306>

### Array order expectation

- <https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/10148>

### Feature tests

- [Be sure to create all the data the test need before starting exercise](https://gitlab.com/gitlab-org/gitlab-foss/issues/32622#note_31128195): <https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/12059>
- [Bis](https://gitlab.com/gitlab-org/gitlab-foss/issues/34609#note_34048715): <https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/12604>
- [Bis](https://gitlab.com/gitlab-org/gitlab-foss/issues/34698#note_34276286): <https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/12664>
- [Assert against the underlying database state instead of against a page's content](https://gitlab.com/gitlab-org/gitlab-foss/issues/31437): <https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/10934>
- In JS tests, shifting elements can cause Capybara to misclick when the element moves at the exact time Capybara sends the click
  - [Dropdowns rendering upward or downward due to window size and scroll position](https://gitlab.com/gitlab-org/gitlab/merge_requests/17660)
  - [Lazy loaded images can cause Capybara to misclick](https://gitlab.com/gitlab-org/gitlab/merge_requests/18713)
- [Triggering JS events before the event handlers are set up](https://gitlab.com/gitlab-org/gitlab/merge_requests/18742)

#### Capybara viewport size related issues

- [Transient failure of spec/features/issues/filtered_search/filter_issues_spec.rb](https://gitlab.com/gitlab-org/gitlab-foss/issues/29241#note_26743936): <https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/10411>

#### Capybara JS driver related issues

- [Don't wait for AJAX when no AJAX request is fired](https://gitlab.com/gitlab-org/gitlab-foss/issues/30461): <https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/10454>
- [Bis](https://gitlab.com/gitlab-org/gitlab-foss/issues/34647): <https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/12626>

#### PhantomJS / WebKit related issues

- Memory is through the roof! (TL;DR: Load images but block images requests!): <https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/12003>

#### Capybara expectation times out

- [Test imports a project (via Sidekiq) that is growing over time, leading to timeouts when the import takes longer than 60 seconds](https://gitlab.com/gitlab-org/gitlab/merge_requests/22599)

## Resources

- [Flaky Tests: Are You Sure You Want to Rerun Them?](http://semaphoreci.com/blog/2017/04/20/flaky-tests.html)
- [How to Deal With and Eliminate Flaky Tests](https://semaphoreci.com/community/tutorials/how-to-deal-with-and-eliminate-flaky-tests)
- [Tips on Treating Flakiness in your Rails Test Suite](http://semaphoreci.com/blog/2017/08/03/tips-on-treating-flakiness-in-your-test-suite.html)
- ['Flaky' tests: a short story](https://www.ombulabs.com/blog/rspec/continuous-integration/how-to-track-down-a-flaky-test.html)
- [Using Insights to Discover Flaky, Slow, and Failed Tests](https://circleci.com/blog/using-insights-to-discover-flaky-slow-and-failed-tests/)

---

[Return to Testing documentation](index.md)
