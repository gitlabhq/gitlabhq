---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Flaky tests

## What's a flaky test?

It's a test that sometimes fails, but if you retry it enough times, it passes,
eventually.

## Quarantined tests

When a test frequently fails in `main`,
[a ~"master:broken" issue](https://about.gitlab.com/handbook/engineering/workflow/#broken-master)
should be created.
If the test cannot be fixed in a timely fashion, there is an impact on the
productivity of all the developers, so it should be placed in quarantine by
assigning the `:quarantine` metadata with the issue URL.

```ruby
it 'should succeed', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/12345' do
  expect(response).to have_gitlab_http_status(:ok)
end
```

This means it is skipped unless run with `--tag quarantine`:

```shell
bin/rspec --tag quarantine
```

**Before putting a test in quarantine, you should make sure that a
~"master:broken" issue exists for it so it doesn't stay in quarantine forever.**

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

On our CI, we use [RSpec::Retry](https://github.com/NoRedInk/rspec-retry) to automatically retry a failing example a few
times (see [`spec/spec_helper.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/spec_helper.rb) for the precise retries count).

We also use a home-made `RspecFlaky::Listener` listener which records flaky
examples in a JSON report file on `main` (`retrieve-tests-metadata` and
`update-tests-metadata` jobs).

This was originally implemented in: <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/13021>.

If you want to enable retries locally, you can use the `RETRIES` environment variable.
For instance `RETRIES=1 bin/rspec ...` would retry the failing examples once.

## Problems we had in the past at GitLab

- [`rspec-retry` is biting us when some API specs fail](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/29242): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/9825>
- [Sporadic RSpec failures due to `PG::UniqueViolation`](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/28307#note_24958837): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/9846>
  - Follow-up: <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10688>
  - [Capybara.reset_session! should be called before requests are blocked](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/33779): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/12224>
- FFaker generates funky data that tests are not ready to handle (and tests should be predictable so that's bad!):
  - [Make `spec/mailers/notify_spec.rb` more robust](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/20121): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10015>
  - [Transient failure in `spec/requests/api/commits_spec.rb`](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/27988#note_25342521): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/9944>
  - [Replace FFaker factory data with sequences](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/29643): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10184>
  - [Transient failure in spec/finders/issues_finder_spec.rb](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/30211#note_26707685): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10404>

### Order-dependent flaky tests

These flaky tests can fail depending on the order they run with other tests. For example:

- <https://gitlab.com/gitlab-org/gitlab/-/issues/327668>

To identify the tests that lead to such failure, we can use `rspec --bisect`,
which would give us the minimal test combination to reproduce the failure:

```shell
rspec --bisect ee/spec/services/ee/merge_requests/update_service_spec.rb ee/spec/services/ee/notes/quick_actions_service_spec.rb ee/spec/services/epic_links/create_service_spec.rb  ee/spec/services/ee/issuable/bulk_update_service_spec.rb
Bisect started using options: "ee/spec/services/ee/merge_requests/update_service_spec.rb ee/spec/services/ee/notes/quick_actions_service_spec.rb ee/spec/services/epic_links/create_service_spec.rb ee/spec/services/ee/issuable/bulk_update_service_spec.rb"
Running suite to find failures... (2 minutes 18.4 seconds)
Starting bisect with 3 failing examples and 144 non-failing examples.
Checking that failure(s) are order-dependent... failure appears to be order-dependent

Round 1: bisecting over non-failing examples 1-144 . ignoring examples 1-72 (1 minute 11.33 seconds)
...
Round 7: bisecting over non-failing examples 132-133 . ignoring example 132 (43.78 seconds)
Bisect complete! Reduced necessary non-failing examples from 144 to 1 in 8 minutes 31 seconds.

The minimal reproduction command is:
  rspec ./ee/spec/services/ee/issuable/bulk_update_service_spec.rb[1:2:1:1:1:1,1:2:1:2:1:1,1:2:1:3:1] ./ee/spec/services/epic_links/create_service_spec.rb[1:1:2:2:6:4]
```

We can reproduce the test failure with the reproduction command above. If we change the order of the tests, the test would pass.

### Time-sensitive flaky tests

- <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10046>
- <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10306>

### Array order expectation

- <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10148>

### Feature tests

- [Be sure to create all the data the test need before starting exercise](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/32622#note_31128195): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/12059>
- [Bis](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/34609#note_34048715): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/12604>
- [Bis](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/34698#note_34276286): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/12664>
- [Assert against the underlying database state instead of against a page's content](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/31437): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10934>
- In JS tests, shifting elements can cause Capybara to mis-click when the element moves at the exact time Capybara sends the click
  - [Dropdowns rendering upward or downward due to window size and scroll position](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17660)
  - [Lazy loaded images can cause Capybara to mis-click](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18713)
- [Triggering JS events before the event handlers are set up](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18742)
- [Wait for the image to be lazy-loaded when asserting on a Markdown image's `src` attribute](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25408)

#### Capybara viewport size related issues

- [Transient failure of spec/features/issues/filtered_search/filter_issues_spec.rb](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/29241#note_26743936): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10411>

#### Capybara JS driver related issues

- [Don't wait for AJAX when no AJAX request is fired](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/30461): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10454>
- [Bis](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/34647): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/12626>

#### PhantomJS / WebKit related issues

- Memory is through the roof! (Load images but block images requests!): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/12003>

#### Capybara expectation times out

- [Test imports a project (via Sidekiq) that is growing over time, leading to timeouts when the import takes longer than 60 seconds](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22599)

## Resources

- [Flaky Tests: Are You Sure You Want to Rerun Them?](https://semaphoreci.com/blog/2017/04/20/flaky-tests.html)
- [How to Deal With and Eliminate Flaky Tests](https://semaphoreci.com/community/tutorials/how-to-deal-with-and-eliminate-flaky-tests)
- [Tips on Treating Flakiness in your Rails Test Suite](https://semaphoreci.com/blog/2017/08/03/tips-on-treating-flakiness-in-your-test-suite.html)
- ['Flaky' tests: a short story](https://www.ombulabs.com/blog/rspec/continuous-integration/how-to-track-down-a-flaky-test.html)
- [Using Insights to Discover Flaky, Slow, and Failed Tests](https://circleci.com/blog/using-insights-to-discover-flaky-slow-and-failed-tests/)

---

[Return to Testing documentation](index.md)
