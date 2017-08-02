# Testing Standards and Style Guidelines

This guide outlines standards and best practices for automated testing of GitLab
CE and EE.

It is meant to be an _extension_ of the [thoughtbot testing
styleguide](https://github.com/thoughtbot/guides/tree/master/style/testing). If
this guide defines a rule that contradicts the thoughtbot guide, this guide
takes precedence. Some guidelines may be repeated verbatim to stress their
importance.

## Definitions

### Unit tests

Formal definition: https://en.wikipedia.org/wiki/Unit_testing

These kind of tests ensure that a single unit of code (a method) works as
expected (given an input, it has a predictable output). These tests should be
isolated as much as possible. For example, model methods that don't do anything
with the database shouldn't need a DB record. Classes that don't need database
records should use stubs/doubles as much as possible.

| Code path | Tests path | Testing engine | Notes |
| --------- | ---------- | -------------- | ----- |
| `app/finders/` | `spec/finders/` | RSpec | |
| `app/helpers/` | `spec/helpers/` | RSpec | |
| `app/db/{post_,}migrate/` | `spec/migrations/` | RSpec | More details at [`spec/migrations/README.md`](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/spec/migrations/README.md). |
| `app/policies/` | `spec/policies/` | RSpec | |
| `app/presenters/` | `spec/presenters/` | RSpec | |
| `app/routing/` | `spec/routing/` | RSpec | |
| `app/serializers/` | `spec/serializers/` | RSpec | |
| `app/services/` | `spec/services/` | RSpec | |
| `app/tasks/` | `spec/tasks/` | RSpec | |
| `app/uploaders/` | `spec/uploaders/` | RSpec | |
| `app/views/` | `spec/views/` | RSpec | |
| `app/workers/` | `spec/workers/` | RSpec | |
| `app/assets/javascripts/` | `spec/javascripts/` | Karma | More details in the [JavaScript](#javascript) section. |

### Integration tests

Formal definition: https://en.wikipedia.org/wiki/Integration_testing

These kind of tests ensure that individual parts of the application work well together, without the overhead of the actual app environment (i.e. the browser). These tests should assert at the request/response level: status code, headers, body. They're useful to test permissions, redirections, what view is rendered etc.

| Code path | Tests path | Testing engine | Notes |
| --------- | ---------- | -------------- | ----- |
| `app/controllers/` | `spec/controllers/` | RSpec | |
| `app/mailers/` | `spec/mailers/` | RSpec | |
| `lib/api/` | `spec/requests/api/` | RSpec | |
| `lib/ci/api/` | `spec/requests/ci/api/` | RSpec | |
| `app/assets/javascripts/` | `spec/javascripts/` | Karma | More details in the [JavaScript](#javascript) section. |

#### About controller tests

In an ideal world, controllers should be thin. However, when this is not the
case, it's acceptable to write a system/feature test without JavaScript instead
of a controller test. The reason is that testing a fat controller usually
involves a lot of stubbing, things like:

```ruby
controller.instance_variable_set(:@user, user)
```

and use methods which are deprecated in Rails 5 ([#23768]).

[#23768]: https://gitlab.com/gitlab-org/gitlab-ce/issues/23768

#### About Karma

As you may have noticed, Karma is both in the Unit tests and the Integration
tests category. That's because Karma is a tool that provides an environment to
run JavaScript tests, so you can either run unit tests (e.g. test a single
JavaScript method), or integration tests (e.g. test a component that is composed
of multiple components).

### System tests or Feature tests

Formal definition: https://en.wikipedia.org/wiki/System_testing.

These kind of tests ensure the application works as expected from a user point
of view (aka black-box testing). These tests should test a happy path for a
given page or set of pages, and a test case should be added for any regression
that couldn't have been caught at lower levels with better tests (i.e. if a
regression is found, regression tests should be added at the lowest-level
possible).

| Tests path | Testing engine | Notes |
| ---------- | -------------- | ----- |
| `spec/features/` | [Capybara] + [RSpec] | If your spec has the `:js` metadata, the browser driver will be [Poltergeist], otherwise it's using [RackTest]. |
| `features/` | Spinach | Spinach tests are deprecated, [you shouldn't add new Spinach tests](#spinach-feature-tests). |

[Capybara]: https://github.com/teamcapybara/capybara
[RSpec]: https://github.com/rspec/rspec-rails#feature-specs
[Poltergeist]: https://github.com/teamcapybara/capybara#poltergeist
[RackTest]: https://github.com/teamcapybara/capybara#racktest

#### Best practices

- Create only the necessary records in the database
- Test a happy path and a less happy path but that's it
- Every other possible path should be tested with Unit or Integration tests
- Test what's displayed on the page, not the internals of ActiveRecord models.
  For instance, if you want to verify that a record was created, add
  expectations that its attributes are displayed on the page, not that
  `Model.count` increased by one.
- It's ok to look for DOM elements but don't abuse it since it makes the tests
  more brittle

If we're confident that the low-level components work well (and we should be if
we have enough Unit & Integration tests), we shouldn't need to duplicate their
thorough testing at the System test level.

It's very easy to add tests, but a lot harder to remove or improve tests, so one
should take care of not introducing too many (slow and duplicated) specs.

The reasons why we should follow these best practices are as follows:

- System tests are slow to run since they spin up the entire application stack
  in a headless browser, and even slower when they integrate a JS driver
- When system tests run with a JavaScript driver, the tests are run in a
  different thread than the application. This means it does not share a
  database connection and your test will have to commit the transactions in
  order for the running application to see the data (and vice-versa). In that
  case we need to truncate the database after each spec instead of simply
  rolling back a transaction (the faster strategy that's in use for other kind
  of tests). This is slower than transactions, however, so we want to use
  truncation only when necessary.

### Black-box tests or End-to-end tests

GitLab consists of [multiple pieces] such as [GitLab Shell], [GitLab Workhorse],
[Gitaly], [GitLab Pages], [GitLab Runner], and GitLab Rails. All theses pieces
are configured and packaged by [GitLab Omnibus].

[GitLab QA] is a tool that allows to test that all these pieces integrate well
together by building a Docker image for a given version of GitLab Rails and
running feature tests (i.e. using Capybara) against it.

The actual test scenarios and steps are [part of GitLab Rails] so that they're
always in-sync with the codebase.

[multiple pieces]: ./architecture.md#components
[GitLab Shell]: https://gitlab.com/gitlab-org/gitlab-shell
[GitLab Workhorse]: https://gitlab.com/gitlab-org/gitlab-workhorse
[Gitaly]: https://gitlab.com/gitlab-org/gitaly
[GitLab Pages]: https://gitlab.com/gitlab-org/gitlab-pages
[GitLab Runner]: https://gitlab.com/gitlab-org/gitlab-ci-multi-runner
[GitLab Omnibus]: https://gitlab.com/gitlab-org/omnibus-gitlab
[GitLab QA]: https://gitlab.com/gitlab-org/gitlab-qa
[part of GitLab Rails]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/qa

## How to test at the correct level?

As many things in life, deciding what to test at each level of testing is a
trade-off:

- Unit tests are usually cheap, and you should consider them like the basement
  of your house: you need them to be confident that your code is behaving
  correctly. However if you run only unit tests without integration / system tests, you might [miss] the [big] [picture]!
- Integration tests are a bit more expensive, but don't abuse them. A feature test
  is often better than an integration test that is stubbing a lot of internals.
- System tests are expensive (compared to unit tests), even more if they require
  a JavaScript driver. Make sure to follow the guidelines in the [Speed](#test-speed)
  section.

Another way to see it is to think about the "cost of tests", this is well
explained [in this article][tests-cost] and the basic idea is that the cost of a
test includes:

- The time it takes to write the test
- The time it takes to run the test every time the suite runs
- The time it takes to understand the test
- The time it takes to fix the test if it breaks and the underlying code is OK
- Maybe, the time it takes to change the code to make the code testable.

[miss]: https://twitter.com/ThePracticalDev/status/850748070698651649
[big]: https://twitter.com/timbray/status/822470746773409794
[picture]: https://twitter.com/withzombies/status/829716565834752000
[tests-cost]: https://medium.com/table-xi/high-cost-tests-and-high-value-tests-a86e27a54df#.2ulyh3a4e

## Frontend testing

Please consult the [dedicated "Frontend testing" guide](./fe_guide/testing.md).

## RSpec

### General Guidelines

- Use a single, top-level `describe ClassName` block.
- Use `described_class` instead of repeating the class name being described
  (_this is enforced by RuboCop_).
- Use `.method` to describe class methods and `#method` to describe instance
  methods.
- Use `context` to test branching logic.
- Use multi-line `do...end` blocks for `before` and `after`, even when it would
  fit on a single line.
- Don't assert against the absolute value of a sequence-generated attribute (see [Gotchas](gotchas.md#dont-assert-against-the-absolute-value-of-a-sequence-generated-attribute)).
- Don't supply the `:each` argument to hooks since it's the default.
- Prefer `not_to` to `to_not` (_this is enforced by RuboCop_).
- Try to match the ordering of tests to the ordering within the class.
- Try to follow the [Four-Phase Test][four-phase-test] pattern, using newlines
  to separate phases.
- Try to use `Gitlab.config.gitlab.host` rather than hard coding `'localhost'`
- On `before` and `after` hooks, prefer it scoped to `:context` over `:all`

[four-phase-test]: https://robots.thoughtbot.com/four-phase-test

### `let` variables

GitLab's RSpec suite has made extensive use of `let` variables to reduce
duplication. However, this sometimes [comes at the cost of clarity][lets-not],
so we need to set some guidelines for their use going forward:

- `let` variables are preferable to instance variables. Local variables are
  preferable to `let` variables.
- Use `let` to reduce duplication throughout an entire spec file.
- Don't use `let` to define variables used by a single test; define them as
  local variables inside the test's `it` block.
- Don't define a `let` variable inside the top-level `describe` block that's
  only used in a more deeply-nested `context` or `describe` block. Keep the
  definition as close as possible to where it's used.
- Try to avoid overriding the definition of one `let` variable with another.
- Don't define a `let` variable that's only used by the definition of another.
  Use a helper method instead.

[lets-not]: https://robots.thoughtbot.com/lets-not

#### `set` variables

In some cases there is no need to recreate the same object for tests again for
each example. For example, a project is needed to test issues on the same
project, one project will do for the entire file. This can be achieved by using
`set` in the same way you would use `let`.

`rspec-set` only works on ActiveRecord objects, and before new examples it
reloads or recreates the model, _only_ if needed. That is, when you changed
properties or destroyed the object.

There is one gotcha; you can't reference a model defined in a `let` block in a
`set` block.

### Time-sensitive tests

[Timecop](https://github.com/travisjeffery/timecop) is available in our
Ruby-based tests for verifying things that are time-sensitive. Any test that
exercises or verifies something time-sensitive should make use of Timecop to
prevent transient test failures.

Example:

```ruby
it 'is overdue' do
  issue = build(:issue, due_date: Date.tomorrow)

  Timecop.freeze(3.days.from_now) do
    expect(issue).to be_overdue
  end
end
```

### System / Feature tests

- Feature specs should be named `ROLE_ACTION_spec.rb`, such as
  `user_changes_password_spec.rb`.
- Use only one `feature` block per feature spec file.
- Use scenario titles that describe the success and failure paths.
- Avoid scenario titles that add no information, such as "successfully".
- Avoid scenario titles that repeat the feature title.

### Matchers

Custom matchers should be created to clarify the intent and/or hide the
complexity of RSpec expectations.They should be placed under
`spec/support/matchers/`. Matchers can be placed in subfolder if they apply to
a certain type of specs only (e.g. features, requests etc.) but shouldn't be if
they apply to multiple type of specs.

### Shared contexts

All shared contexts should be be placed under `spec/support/shared_contexts/`.
Shared contexts can be placed in subfolder if they apply to a certain type of
specs only (e.g. features, requests etc.) but shouldn't be if they apply to
multiple type of specs.

Each file should include only one context and have a descriptive name, e.g.
`spec/support/shared_contexts/controllers/githubish_import_controller_shared_context.rb`.

### Shared examples

All shared examples should be be placed under `spec/support/shared_examples/`.
Shared examples can be placed in subfolder if they apply to a certain type of
specs only (e.g. features, requests etc.) but shouldn't be if they apply to
multiple type of specs.

Each file should include only one context and have a descriptive name, e.g.
`spec/support/shared_examples/controllers/githubish_import_controller_shared_example.rb`.

### Helpers

Helpers are usually modules that provide some methods to hide the complexity of
specific RSpec examples. You can define helpers in RSpec files if they're not
intended to be shared with other specs. Otherwise, they should be be placed
under `spec/support/helpers/`. Helpers can be placed in subfolder if they apply
to a certain type of specs only (e.g. features, requests etc.) but shouldn't be
if they apply to multiple type of specs.

Helpers should follow the Rails naming / namespacing convention. For instance
`spec/support/helpers/cycle_analytics_helpers.rb` should define:

```ruby
module Spec
  module Support
    module Helpers
      module CycleAnalyticsHelpers
        def create_commit_referencing_issue(issue, branch_name: random_git_name)
          project.repository.add_branch(user, branch_name, 'master')
          create_commit("Commit for ##{issue.iid}", issue.project, user, branch_name)
        end
      end
    end
  end
end
```

Helpers should not change the RSpec config. For instance, the helpers module
described above should not include:

```ruby
RSpec.configure do |config|
  config.include Spec::Support::Helpers::CycleAnalyticsHelpers
end
```

### Factories

GitLab uses [factory_girl] as a test fixture replacement.

- Factory definitions live in `spec/factories/`, named using the pluralization
  of their corresponding model (`User` factories are defined in `users.rb`).
- There should be only one top-level factory definition per file.
- FactoryGirl methods are mixed in to all RSpec groups. This means you can (and
  should) call `create(...)` instead of `FactoryGirl.create(...)`.
- Make use of [traits] to clean up definitions and usages.
- When defining a factory, don't define attributes that are not required for the
  resulting record to pass validation.
- When instantiating from a factory, don't supply attributes that aren't
  required by the test.
- Factories don't have to be limited to `ActiveRecord` objects.
  [See example](https://gitlab.com/gitlab-org/gitlab-ce/commit/0b8cefd3b2385a21cfed779bd659978c0402766d).

[factory_girl]: https://github.com/thoughtbot/factory_girl
[traits]: http://www.rubydoc.info/gems/factory_girl/file/GETTING_STARTED.md#Traits

### Fixtures

All fixtures should be be placed under `spec/fixtures/`.

### Config

RSpec config files are files that change the RSpec config (i.e.
`RSpec.configure do |config|` blocks). They should be placed under
`spec/support/config/`.

Each file should be related to a specific domain, e.g.
`spec/support/config/capybara.rb`, `spec/support/config/carrierwave.rb`, etc.

Helpers can be included in the `spec/support/config/rspec.rb` file. If a
helpers module applies only to a certain kind of specs, it should add modifiers
to the `config.include` call. For instance if
`spec/support/helpers/cycle_analytics_helpers.rb` applies to `:lib` and
`type: :model` specs only, you would write the following:

```ruby
RSpec.configure do |config|
  config.include Spec::Support::Helpers::CycleAnalyticsHelpers, :lib
  config.include Spec::Support::Helpers::CycleAnalyticsHelpers, type: :model
end
```

## Testing Rake Tasks

To make testing Rake tasks a little easier, there is a helper that can be included
in lieu of the standard Spec helper. Instead of `require 'spec_helper'`, use
`require 'rake_helper'`. The helper includes `spec_helper` for you, and configures
a few other things to make testing Rake tasks easier.

At a minimum, requiring the Rake helper will redirect `stdout`, include the
runtime task helpers, and include the `RakeHelpers` Spec support module.

The `RakeHelpers` module exposes a `run_rake_task(<task>)` method to make
executing tasks simple. See `spec/support/rake_helpers.rb` for all available
methods.

Example:

```ruby
require 'rake_helper'

describe 'gitlab:shell rake tasks' do
  before do
    Rake.application.rake_require 'tasks/gitlab/shell'

    stub_warn_user_is_not_gitlab
  end

 describe 'install task' do
    it 'invokes create_hooks task' do
      expect(Rake::Task['gitlab:shell:create_hooks']).to receive(:invoke)

      run_rake_task('gitlab:shell:install')
    end
  end
end
```

## Test speed

GitLab has a massive test suite that, without [parallelization], can take hours
to run. It's important that we make an effort to write tests that are accurate
and effective _as well as_ fast.

Here are some things to keep in mind regarding test performance:

- `double` and `spy` are faster than `FactoryGirl.build(...)`
- `FactoryGirl.build(...)` and `.build_stubbed` are faster than `.create`.
- Don't `create` an object when `build`, `build_stubbed`, `attributes_for`,
  `spy`, or `double` will do. Database persistence is slow!
- Use `create(:empty_project)` instead of `create(:project)` when you don't need
  the underlying Git repository. Filesystem operations are slow!
- Don't mark a feature as requiring JavaScript (through `@javascript` in
  Spinach or `:js` in RSpec) unless it's _actually_ required for the test
  to be valid. Headless browser testing is slow!

[parallelization]: #test-suite-parallelization-on-the-ci

### Test suite parallelization on the CI

Our current CI parallelization setup is as follows:

1. The `knapsack` job in the prepare stage that is supposed to ensure we have a
  `knapsack/${CI_PROJECT_NAME}/rspec_report-master.json` file:
  - The `knapsack/${CI_PROJECT_NAME}/rspec_report-master.json` file is fetched
    from S3, if it's not here we initialize the file with `{}`.
1. Each `rspec x y` job are run with `knapsack rspec` and should have an evenly
  distributed share of tests:
  - It works because the jobs have access to the
    `knapsack/${CI_PROJECT_NAME}/rspec_report-master.json` since the "artifacts
    from all previous stages are passed by default". [^1]
  - the jobs set their own report path to
    `KNAPSACK_REPORT_PATH=knapsack/${CI_PROJECT_NAME}/${JOB_NAME[0]}_node_${CI_NODE_INDEX}_${CI_NODE_TOTAL}_report.json`.
  - if knapsack is doing its job, test files that are run should be listed under
    `Report specs`, not under `Leftover specs`.
1. The `update-knapsack` job takes all the
  `knapsack/${CI_PROJECT_NAME}/${JOB_NAME[0]}_node_${CI_NODE_INDEX}_${CI_NODE_TOTAL}_report.json`
  files from the `rspec x y` jobs and merge them all together into a single
  `knapsack/${CI_PROJECT_NAME}/rspec_report-master.json` file that is then
  uploaded to S3.

After that, the next pipeline will use the up-to-date
`knapsack/${CI_PROJECT_NAME}/rspec_report-master.json` file. The same strategy
is used for Spinach tests as well.

### Monitoring

The GitLab test suite is [monitored] for the `master` branch, and any branch
that includes `rspec-profile` in their name.

A [public dashboard] is available for everyone to see. Feel free to look at the
slowest test files and try to improve them.

[monitored]: ./performance.md#rspec-profiling
[public dashboard]: https://redash.gitlab.com/public/dashboards/l1WhHXaxrCWM5Ai9D7YDqHKehq6OU3bx5gssaiWe?org_slug=default

## CI setup

- On CE, the test suite only runs against PostgreSQL by default. We additionally
  run the suite against MySQL for tags, `master`, and any branch that includes
  `mysql` in the name.
- On EE, the test suite always runs both PostgreSQL and MySQL.
- Rails logging to `log/test.log` is disabled by default in CI [for
  performance reasons][logging]. To override this setting, provide the
  `RAILS_ENABLE_TEST_LOG` environment variable.

[logging]: https://jtway.co/speed-up-your-rails-test-suite-by-6-in-1-line-13fedb869ec4

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

[Return to Development documentation](README.md)

[^1]: /ci/yaml/README.html#dependencies
