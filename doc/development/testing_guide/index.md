# Testing standards and style guidelines

This document describes various guidelines and best practices for automated
testing of the GitLab project.

It is meant to be an _extension_ of the [thoughtbot testing
styleguide](https://github.com/thoughtbot/guides/tree/master/style/testing). If
this guide defines a rule that contradicts the thoughtbot guide, this guide
takes precedence. Some guidelines may be repeated verbatim to stress their
importance.

## Overview

GitLab is built on top of [Ruby on Rails][rails], and we're using [RSpec] for all
the backend tests, with [Capybara] for end-to-end integration testing.
On the frontend side, we're using [Karma] and [Jasmine] for JavaScript unit and
integration testing.

Following are two great articles that everyone should read to understand what
automated testing means, and what are its principles:

- [Five Factor Testing](https://www.devmynd.com/blog/five-factor-testing): Why do we need tests?
- [Principles of Automated Testing](http://www.lihaoyi.com/post/PrinciplesofAutomatedTesting.html): Levels of testing. Prioritize tests. Cost of tests.

---

## [Testing levels](testing_levels.md)

Learn about the different testing levels, and how to decide at what level your
changes should be tested.

---

## [Testing best practices](best_practices.md)

Everything you should know about how to write good tests: RSpec, FactoryBot,
system tests, parameterized tests etc.

---

## [Frontend testing standards and style guidelines](frontend_testing.md)

Everything you should know about how to write good Frontend tests: Karma,
testing promises, stubbing etc.

---

## [Flaky tests](flaky_tests.md)

What are flaky tests, the different kind of flaky tests we encountered, and what
we do about them.

---

## [GitLab tests in the Continuous Integration (CI) context](ci.md)

How GitLab test suite is run in the CI context: setup, caches, artifacts,
parallelization, monitoring.

---

## [Testing Rake tasks](testing_rake_tasks.md)

Everything you should know about how to test Rake tasks.

---

## [End-to-end tests](end_to_end_tests.md)

Everything you should know about how to run end-to-end tests using
[GitLab QA][gitlab-qa] testing framework.

---

## Spinach (feature) tests

GitLab [moved from Cucumber to Spinach](https://github.com/gitlabhq/gitlabhq/pull/1426)
for its feature/integration tests in September 2012.

As of March 2016, we are [trying to avoid adding new Spinach
tests](https://gitlab.com/gitlab-org/gitlab-ce/issues/14121) going forward,
opting for [RSpec feature](#features-integration) specs.

Adding new Spinach scenarios is acceptable _only if_ the new scenario requires
no more than one new `step` definition. If more than that is required, the
test should be re-implemented using RSpec instead.

---

[Return to Development documentation](../README.md)

[^1]: /ci/yaml/README.html#dependencies

[rails]: http://rubyonrails.org/
[RSpec]: https://github.com/rspec/rspec-rails#feature-specs
[Capybara]: https://github.com/teamcapybara/capybara
[Karma]: http://karma-runner.github.io/
[Jasmine]: https://jasmine.github.io/
[gitlab-qa]: https://gitlab.com/gitlab-org/gitlab-qa
