---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Testing standards and style guidelines

This document describes various guidelines and best practices for automated
testing of the GitLab project.

It is meant to be an _extension_ of the [Thoughtbot testing
style guide](https://github.com/thoughtbot/guides/tree/master/testing-rspec). If
this guide defines a rule that contradicts the Thoughtbot guide, this guide
takes precedence. Some guidelines may be repeated verbatim to stress their
importance.

## Overview

GitLab is built on top of [Ruby on Rails](https://rubyonrails.org/), and we're using [RSpec](https://github.com/rspec/rspec-rails#feature-specs) for all
the backend tests, with [Capybara](https://github.com/teamcapybara/capybara) for end-to-end integration testing.
On the frontend side, we're using [Jest](https://jestjs.io/) and [Karma](http://karma-runner.github.io/)/[Jasmine](https://jasmine.github.io/) for JavaScript unit and
integration testing.

Following are two great articles that everyone should read to understand what
automated testing means, and what are its principles:

- [Five Factor Testing](https://madeintandem.com/blog/five-factor-testing/): Why do we need tests?
- [Principles of Automated Testing](https://www.lihaoyi.com/post/PrinciplesofAutomatedTesting.html): Levels of testing. Prioritize tests. Cost of tests.

## [Testing levels](testing_levels.md)

Learn about the different testing levels, and how to decide at what level your
changes should be tested.

## [Testing best practices](best_practices.md)

Everything you should know about how to write good tests: Test Design, RSpec, FactoryBot,
system tests, parameterized tests etc.

## [Frontend testing standards and style guidelines](frontend_testing.md)

Everything you should know about how to write good Frontend tests: Karma,
testing promises, stubbing etc.

## [Flaky tests](flaky_tests.md)

What are flaky tests, the different kind of flaky tests we encountered, and what
we do about them.

## [GitLab tests in the Continuous Integration (CI) context](ci.md)

How GitLab test suite is run in the CI context: setup, caches, artifacts,
parallelization, monitoring.

## [Review apps](review_apps.md)

How review apps are set up for GitLab CE/EE and how to use them.

## [Testing Rake tasks](testing_rake_tasks.md)

Everything you should know about how to test Rake tasks.

## [End-to-end tests](end_to_end/index.md)

Everything you should know about how to run end-to-end tests using
[GitLab QA](https://gitlab.com/gitlab-org/gitlab-qa) testing framework.

## [Migrations tests](testing_migrations_guide.md)

Everything you should know about how to test migrations.

[Return to Development documentation](../index.md)
