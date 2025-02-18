---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Testing standards and style guidelines
---

This document describes various guidelines and best practices for automated
testing of the GitLab project.

It is meant to be an _extension_ of the
[thoughtbot testing style guide](https://github.com/thoughtbot/guides/tree/master/testing-rspec). If
this guide defines a rule that contradicts the thoughtbot guide, this guide
takes precedence. Some guidelines may be repeated verbatim to stress their
importance.

## Overview

GitLab is built on top of [Ruby on Rails](https://rubyonrails.org/), and we're using [RSpec](https://github.com/rspec/rspec-rails#feature-specs) for all
the backend tests, with [Capybara](https://github.com/teamcapybara/capybara) for end-to-end integration testing.
On the frontend side, we're using [Jest](https://jestjs.io/) for JavaScript unit and
integration testing.

Following are two great articles that everyone should read to understand what
automated testing means, and what are its principles:

- [Five Factor Testing](https://madeintandem.com/blog/five-factor-testing/): Why do we need tests?
- [Principles of Automated Testing](https://www.lihaoyi.com/post/PrinciplesofAutomatedTesting.html): Levels of testing. Prioritize tests. Cost of tests.

## Testing levels

Learn about the different [testing levels](testing_levels.md), and how to decide at what level your
changes should be tested.

## Testing best practices

Everything you should know about [how to write good tests](best_practices.md): Test Design, RSpec, FactoryBot,
system tests, parameterized tests etc.

## Frontend testing standards and style guidelines

Everything you should know about [how to write good Frontend tests](frontend_testing.md): Jest,
testing promises, stubbing etc.

## Getting started with Feature tests

Need to [get started with feature tests](frontend_testing.md#get-started-with-feature-tests)? Here are some general guidelines,
tips and tricks to get the most out of white-box testing.

## Flaky tests

What are [flaky tests](flaky_tests.md), the different kind of flaky tests we encountered, and what
we do about them.

## GitLab pipelines

How GitLab test suite [is run in the CI context](../pipelines/_index.md): setup, caches, artifacts,
parallelization, monitoring.

## Review apps

How [review apps](review_apps.md) are set up for GitLab CE/EE and how to use them.

## Testing Rake tasks

Everything you should know about [how to test Rake tasks](testing_rake_tasks.md).

## End-to-end tests

Everything you should know about [how to run end-to-end tests](end_to_end/_index.md) using
[GitLab QA](https://gitlab.com/gitlab-org/gitlab-qa) testing framework.

## Migrations tests

Everything you should know about [how to test migrations](testing_migrations_guide.md).

## Contract tests

[Introduction to contract testing](contract/_index.md), how to run the tests, and how to write them.

## Test results tracking

How we track our [test suite run results](test_results_tracking.md).

[Return to Development documentation](../_index.md)
