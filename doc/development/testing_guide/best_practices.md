# Testing best practices

## Test Design

Testing at GitLab is a first class citizen, not an afterthought. It's important we consider the design of our tests
as we do the design of our features.

When implementing a feature, we think about developing the right capabilities the right way, which helps us
narrow our scope to a manageable level. When implementing tests for a feature, we must think about developing
the right tests, but then cover _all_ the important ways the test may fail, which can quickly widen our scope to
a level that is difficult to manage.

Test heuristics can help solve this problem. They concisely address many of the common ways bugs
manifest themselves within our code. When designing our tests, take time to review known test heuristics to inform
our test design. We can find some helpful heuristics documented in the Handbook in the
[Test Engineering](https://about.gitlab.com/handbook/engineering/quality/test-engineering/#test-heuristics) section.

## Test speed

GitLab has a massive test suite that, without [parallelization], can take hours
to run. It's important that we make an effort to write tests that are accurate
and effective _as well as_ fast.

Here are some things to keep in mind regarding test performance:

- `double` and `spy` are faster than `FactoryBot.build(...)`
- `FactoryBot.build(...)` and `.build_stubbed` are faster than `.create`.
- Don't `create` an object when `build`, `build_stubbed`, `attributes_for`,
  `spy`, or `double` will do. Database persistence is slow!
- Don't mark a feature as requiring JavaScript (through `:js` in RSpec) unless it's _actually_ required for the test
  to be valid. Headless browser testing is slow!

[parallelization]: ci.md#test-suite-parallelization-on-the-ci

## RSpec

To run rspec tests:

```sh
# run all tests
bundle exec rspec

# run test for path
bundle exec rspec spec/[path]/[to]/[spec].rb
```

Use [guard](https://github.com/guard/guard) to continuously monitor for changes and only run matching tests:

```sh
bundle exec guard
```

When using spring and guard together, use `SPRING=1 bundle exec guard` instead to make use of spring.

### General guidelines

- Use a single, top-level `describe ClassName` block.
- Use `.method` to describe class methods and `#method` to describe instance
  methods.
- Use `context` to test branching logic.
- Try to match the ordering of tests to the ordering within the class.
- Try to follow the [Four-Phase Test](https://thoughtbot.com/blog/four-phase-test) pattern, using newlines
  to separate phases.
- Use `Gitlab.config.gitlab.host` rather than hard coding `'localhost'`
- Don't assert against the absolute value of a sequence-generated attribute (see
  [Gotchas](../gotchas.md#do-not-assert-against-the-absolute-value-of-a-sequence-generated-attribute)).
- Don't supply the `:each` argument to hooks since it's the default.
- On `before` and `after` hooks, prefer it scoped to `:context` over `:all`
- When using `evaluate_script("$('.js-foo').testSomething()")` (or `execute_script`) which acts on a given element,
  use a Capybara matcher beforehand (e.g. `find('.js-foo')`) to ensure the element actually exists.
- Use `focus: true` to isolate parts of the specs you want to run.
- Use [`:aggregate_failures`](https://relishapp.com/rspec/rspec-core/docs/expectation-framework-integration/aggregating-failures) when there is more than one expectation in a test.
- For [empty test description blocks](https://github.com/rubocop-hq/rspec-style-guide#it-and-specify), use `specify` rather than `it do` if the test is self-explanatory.

### System / Feature tests

NOTE: **Note:** Before writing a new system test, [please consider **not**
writing one](testing_levels.md#consider-not-writing-a-system-test)!

- Feature specs should be named `ROLE_ACTION_spec.rb`, such as
  `user_changes_password_spec.rb`.
- Use scenario titles that describe the success and failure paths.
- Avoid scenario titles that add no information, such as "successfully".
- Avoid scenario titles that repeat the feature title.
- Create only the necessary records in the database
- Test a happy path and a less happy path but that's it
- Every other possible path should be tested with Unit or Integration tests
- Test what's displayed on the page, not the internals of ActiveRecord models.
  For instance, if you want to verify that a record was created, add
  expectations that its attributes are displayed on the page, not that
  `Model.count` increased by one.
- It's ok to look for DOM elements but don't abuse it since it makes the tests
  more brittle

#### Debugging Capybara

Sometimes you may need to debug Capybara tests by observing browser behavior.

#### Live debug

You can pause Capybara and view the website on the browser by using the
`live_debug` method in your spec. The current page will be automatically opened
in your default browser.
You may need to sign in first (the current user's credentials are displayed in
the terminal).

To resume the test run, press any key.

For example:

```
$ bin/rspec spec/features/auto_deploy_spec.rb:34
Running via Spring preloader in process 8999
Run options: include {:locations=>{"./spec/features/auto_deploy_spec.rb"=>[34]}}

Current example is paused for live debugging
The current user credentials are: user2 / 12345678
Press any key to resume the execution of the example!
Back to the example!
.

Finished in 34.51 seconds (files took 0.76702 seconds to load)
1 example, 0 failures
```

Note: `live_debug` only works on JavaScript enabled specs.

#### Run `:js` spec in a visible browser

Run the spec with `CHROME_HEADLESS=0`, e.g.:

```
CHROME_HEADLESS=0 bundle exec rspec some_spec.rb
```

The test will go by quickly, but this will give you an idea of what's happening.
Using `live_debug` with `CHROME_HEADLESS=0` pauses the open browser, and does not
open the page again. This can be used to debug and inspect elements.

You can also add `byebug` or `binding.pry` to pause execution and [step through](../pry_debugging.md#stepping)
the test.

#### Screenshots

We use the `capybara-screenshot` gem to automatically take a screenshot on
failure. In CI you can download these files as job artifacts.

Also, you can manually take screenshots at any point in a test by adding the
methods below. Be sure to remove them when they are no longer needed! See
<https://github.com/mattheworiordan/capybara-screenshot#manual-screenshots> for
more.

Add `screenshot_and_save_page` in a `:js` spec to screenshot what Capybara
"sees", and save the page source.

Add `screenshot_and_open_image` in a `:js` spec to screenshot what Capybara
"sees", and automatically open the image.

The HTML dumps created by this are missing CSS.
This results in them looking very different from the actual application.
There is a [small hack](https://gitlab.com/gitlab-org/gitlab-foss/snippets/1718469) to add CSS which makes debugging easier.

### Fast unit tests

Some classes are well-isolated from Rails and you should be able to test them
without the overhead added by the Rails environment and Bundler's `:default`
group's gem loading. In these cases, you can `require 'fast_spec_helper'`
instead of `require 'spec_helper'` in your test file, and your test should run
really fast since:

- Gems loading is skipped
- Rails app boot is skipped
- GitLab Shell and Gitaly setup are skipped
- Test repositories setup are skipped

`fast_spec_helper` also support autoloading classes that are located inside the
`lib/` directory. It means that as long as your class / module is using only
code from the `lib/` directory you will not need to explicitly load any
dependencies. `fast_spec_helper` also loads all ActiveSupport extensions,
including core extensions that are commonly used in the Rails environment.

Note that in some cases, you might still have to load some dependencies using
`require_dependency` when a code is using gems or a dependency is not located
in `lib/`.

For example, if you want to test your code that is calling the
`Gitlab::UntrustedRegexp` class, which under the hood uses `re2` library, you
should either add `require_dependency 're2'` to files in your library that
need `re2` gem, to make this requirement explicit, or you can add it to the
spec itself, but the former is preferred.

It takes around one second to load tests that are using `fast_spec_helper`
instead of 30+ seconds in case of a regular `spec_helper`.

### `let` variables

GitLab's RSpec suite has made extensive use of `let`(along with it strict, non-lazy
version `let!`) variables to reduce duplication. However, this sometimes [comes at the cost of clarity](https://thoughtbot.com/blog/lets-not),
so we need to set some guidelines for their use going forward:

- `let!` variables are preferable to instance variables. `let` variables
  are preferable to `let!` variables. Local variables are preferable to
  `let` variables.
- Use `let` to reduce duplication throughout an entire spec file.
- Don't use `let` to define variables used by a single test; define them as
  local variables inside the test's `it` block.
- Don't define a `let` variable inside the top-level `describe` block that's
  only used in a more deeply-nested `context` or `describe` block. Keep the
  definition as close as possible to where it's used.
- Try to avoid overriding the definition of one `let` variable with another.
- Don't define a `let` variable that's only used by the definition of another.
  Use a helper method instead.
- `let!` variables should be used only in case if strict evaluation with defined
  order is required, otherwise `let` will suffice. Remember that `let` is lazy and won't
  be evaluated until it is referenced.

### Common test setup

In some cases, there is no need to recreate the same object for tests
again for each example. For example, a project and a guest of that project
is needed to test issues on the same project, one project and user will do for the entire file.
This can be achieved by using
[`let_it_be`](https://test-prof.evilmartians.io/#/let_it_be) variables and the
[`before_all`](https://test-prof.evilmartians.io/#/before_all) hook
from the [`test-prof` gem](https://rubygems.org/gems/test-prof).

```
let_it_be(:project) { create(:project) }
let_it_be(:user) { create(:user) }

before_all do
  project.add_guest(user)
end
```

This will result in only one `Project`, `User`, and `ProjectMember` created for this context.

`let_it_be` and `before_all` are also available within nested contexts. Cleanup after the context
is handled automatically using a transaction rollback.

Note that if you modify an object defined inside a `let_it_be` block,
then you will need to reload the object as needed, or specify the `reload`
option to reload for every example.

```
let_it_be(:project, reload: true) { create(:project) }
```

You can also specify the `refind` option as well to completely load a
new object.

```
let_it_be(:project, refind: true) { create(:project) }
```

### `set` variables

NOTE: **Note:**
We are incrementally removing `set` in favour of `let_it_be`. See the
[removal issue](https://gitlab.com/gitlab-org/gitlab/issues/27922).

In some cases there is no need to recreate the same object for tests again for
each example. For example, a project is needed to test issues on the same
project, one project will do for the entire file. This can be achieved by using
`set` in the same way you would use `let`.

`rspec-set` only works on ActiveRecord objects, and before new examples it
reloads or recreates the model, _only_ if needed. That is, when you changed
properties or destroyed the object.

Note that you can't reference a model defined in a `let` block in a `set` block.

Also, `set` is not supported in `:js` specs since those don't use transactions
to clean up database state after each example.

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

### Feature flags in tests

All feature flags are stubbed to be enabled by default in our Ruby-based
tests.

To disable a feature flag in a test, use the `stub_feature_flags`
helper. For example, to globally disable the `ci_live_trace` feature
flag in a test:

```ruby
stub_feature_flags(ci_live_trace: false)

Feature.enabled?(:ci_live_trace) # => false
```

If you wish to set up a test where a feature flag is disabled for some
actors and not others, you can specify this in options passed to the
helper. For example, to disable the `ci_live_trace` feature flag for a
specifc project:

```ruby
project1, project2 = build_list(:project, 2)

# Feature will only be disabled for project1
stub_feature_flags(ci_live_trace: { enabled: false, thing: project1 })

Feature.enabled?(:ci_live_trace, project1) # => false
Feature.enabled?(:ci_live_trace, project2) # => true
```

### Pristine test environments

The code exercised by a single GitLab test may access and modify many items of
data. Without careful preparation before a test runs, and cleanup afterward,
data can be changed by a test in such a way that it affects the behaviour of
following tests. This should be avoided at all costs! Fortunately, the existing
test framework handles most cases already.

When the test environment does get polluted, a common outcome is
[flaky tests](flaky_tests.md). Pollution will often manifest as an order
dependency: running spec A followed by spec B will reliably fail, but running
spec B followed by spec A will reliably succeed. In these cases, you can use
`rspec --bisect` (or a manual pairwise bisect of spec files) to determine which
spec is at fault. Fixing the problem requires some understanding of how the test
suite ensures the environment is pristine. Read on to discover more about each
data store!

#### SQL database

This is managed for us by the `database_cleaner` gem. Each spec is surrounded in
a transaction, which is rolled back once the test completes. Certain specs will
instead issue `DELETE FROM` queries against every table after completion; this
allows the created rows to be viewed from multiple database connections, which
is important for specs that run in a browser, or migration specs, among others.

One consequence of using these strategies, instead of the well-known
`TRUNCATE TABLES` approach, is that primary keys and other sequences are **not**
reset across specs. So if you create a project in spec A, then create a project
in spec B, the first will have `id=1`, while the second will have `id=2`.

This means that specs should **never** rely on the value of an ID, or any other
sequence-generated column. To avoid accidental conflicts, specs should also
avoid manually specifying any values in these kinds of columns. Instead, leave
them unspecified, and look up the value after the row is created.

#### Redis

GitLab stores two main categories of data in Redis: cached items, and Sidekiq
jobs.

In most specs, the Rails cache is actually an in-memory store. This is replaced
between specs, so calls to `Rails.cache.read` and `Rails.cache.write` are safe.
However, if a spec makes direct Redis calls, it should mark itself with the
`:clean_gitlab_redis_cache`, `:clean_gitlab_redis_shared_state` or
`:clean_gitlab_redis_queues` traits as appropriate.

#### Background jobs / Sidekiq

By default, Sidekiq jobs are enqueued into a jobs array and aren't processed.
If a test enqueues Sidekiq jobs and need them to be processed, the
`:sidekiq_inline` trait can be used.

The `:sidekiq_might_not_need_inline` trait was added when [Sidekiq inline mode was
changed to fake mode](https://gitlab.com/gitlab-org/gitlab/merge_requests/15479)
to all the tests that needed Sidekiq to actually process jobs. Tests with
this trait should be either fixed to not rely on Sidekiq processing jobs, or their
`:sidekiq_might_not_need_inline` trait should be updated to `:sidekiq_inline` if
the processing of background jobs is needed/expected.

NOTE: **Note:**
The usage of `perform_enqueued_jobs` is currently useless since our
workers aren't inheriting from `ApplicationJob` / `ActiveJob::Base`.

#### Filesystem

Filesystem data can be roughly split into "repositories", and "everything else".
Repositories are stored in `tmp/tests/repositories`. This directory is emptied
before a test run starts, and after the test run ends. It is not emptied between
specs, so created repositories accumulate within this directory over the
lifetime of the process. Deleting them is expensive, but this could lead to
pollution unless carefully managed.

To avoid this, [hashed storage](../../administration/repository_storage_types.md)
is enabled in the test suite. This means that repositories are given a unique
path that depends on their project's ID. Since the project IDs are not reset
between specs, this guarantees that each spec gets its own repository on disk,
and prevents changes from being visible between specs.

If a spec manually specifies a project ID, or inspects the state of the
`tmp/tests/repositories/` directory directly, then it should clean up the
directory both before and after it runs. In general, these patterns should be
completely avoided.

Other classes of file linked to database objects, such as uploads, are generally
managed in the same way. With hashed storage enabled in the specs, they are
written to disk in locations determined by ID, so conflicts should not occur.

Some specs disable hashed storage by passing the `:legacy_storage` trait to the
`projects` factory. Specs that do this must **never** override the `path` of the
project, or any of its groups. The default path includes the project ID, so will
not conflict; but if two specs create a `:legacy_storage` project with the same
path, they will use the same repository on disk and lead to test environment
pollution.

Other files must be managed manually by the spec. If you run code that creates a
`tmp/test-file.csv` file, for instance, the spec must ensure that the file is
removed as part of cleanup.

#### Persistent in-memory application state

All the specs in a given `rspec` run share the same Ruby process, which means
they can affect each other by modifying Ruby objects that are accessible between
specs. In practice, this means global variables, and constants (which includes
Ruby classes, modules, etc).

Global variables should generally not be modified. If absolutely necessary, a
block like this can be used to ensure the change is rolled back afterwards:

```ruby
around(:each) do |example|
  old_value = $0

  begin
    $0 = "new-value"
    example.run
  ensure
    $0 = old_value
  end
end
```

If a spec needs to modify a constant, it should use the `stub_const` helper to
ensure the change is rolled back.

If you need to modify the contents of the `ENV` constant, you can use the
`stub_env` helper method instead.

While most Ruby **instances** are not shared between specs, **classes**
and **modules** generally are. Class and module instance variables, accessors,
class variables, and other stateful idioms, should be treated in the same way as
global variables - don't modify them unless you have to! In particular, prefer
using expectations, or dependency injection along with stubs, to avoid the need
for modifications. If you have no other choice, an `around` block similar to the
example for global variables, above, can be used, but this should be avoided if
at all possible.

### Table-based / Parameterized tests

This style of testing is used to exercise one piece of code with a comprehensive
range of inputs. By specifying the test case once, alongside a table of inputs
and the expected output for each, your tests can be made easier to read and more
compact.

We use the [rspec-parameterized](https://github.com/tomykaira/rspec-parameterized)
gem. A short example, using the table syntax and checking Ruby equality for a
range of inputs, might look like this:

```ruby
describe "#==" do
  using RSpec::Parameterized::TableSyntax

  where(:a, :b, :result) do
    1         | 1        | true
    1         | 2        | false
    true      | true     | true
    true      | false    | false
  end

  with_them do
    it { expect(a == b).to eq(result) }

    it 'is isomorphic' do
      expect(b == a).to eq(result)
    end
  end
end
```

CAUTION: **Caution:**
Only use simple values as input in the `where` block. Using procs, stateful
objects, FactoryBot-created objects etc. can lead to
[unexpected results](https://github.com/tomykaira/rspec-parameterized/issues/8).

### Prometheus tests

Prometheus metrics may be preserved from one test run to another. To ensure that metrics are
reset before each example, add the `:prometheus` tag to the Rspec test.

### Matchers

Custom matchers should be created to clarify the intent and/or hide the
complexity of RSpec expectations.They should be placed under
`spec/support/matchers/`. Matchers can be placed in subfolder if they apply to
a certain type of specs only (e.g. features, requests etc.) but shouldn't be if
they apply to multiple type of specs.

#### `be_like_time`

Time returned from a database can differ in precision from time objects
in Ruby, so we need flexible tolerances when comparing in specs. We can
use `be_like_time` to compare that times are within one second of each
other.

Example:

```ruby
expect(metrics.merged_at).to be_like_time(time)
```

#### `have_gitlab_http_status`

Prefer `have_gitlab_http_status` over `have_http_status` because the former
could also show the response body whenever the status mismatched. This would
be very useful whenever some tests start breaking and we would love to know
why without editing the source and rerun the tests.

This is especially useful whenever it's showing 500 internal server error.

### Shared contexts

All shared contexts should be placed under `spec/support/shared_contexts/`.
Shared contexts can be placed in subfolder if they apply to a certain type of
specs only (e.g. features, requests etc.) but shouldn't be if they apply to
multiple type of specs.

Each file should include only one context and have a descriptive name, e.g.
`spec/support/shared_contexts/controllers/githubish_import_controller_shared_context.rb`.

### Shared examples

All shared examples should be placed under `spec/support/shared_examples/`.
Shared examples can be placed in subfolder if they apply to a certain type of
specs only (e.g. features, requests etc.) but shouldn't be if they apply to
multiple type of specs.

Each file should include only one context and have a descriptive name, e.g.
`spec/support/shared_examples/controllers/githubish_import_controller_shared_example.rb`.

### Helpers

Helpers are usually modules that provide some methods to hide the complexity of
specific RSpec examples. You can define helpers in RSpec files if they're not
intended to be shared with other specs. Otherwise, they should be placed
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

GitLab uses [factory_bot] as a test fixture replacement.

- Factory definitions live in `spec/factories/`, named using the pluralization
  of their corresponding model (`User` factories are defined in `users.rb`).
- There should be only one top-level factory definition per file.
- FactoryBot methods are mixed in to all RSpec groups. This means you can (and
  should) call `create(...)` instead of `FactoryBot.create(...)`.
- Make use of [traits](https://www.rubydoc.info/gems/factory_bot/file/GETTING_STARTED.md#Traits) to clean up definitions and usages.
- When defining a factory, don't define attributes that are not required for the
  resulting record to pass validation.
- When instantiating from a factory, don't supply attributes that aren't
  required by the test.
- Factories don't have to be limited to `ActiveRecord` objects.
  [See example](https://gitlab.com/gitlab-org/gitlab-foss/commit/0b8cefd3b2385a21cfed779bd659978c0402766d).

[factory_bot]: https://github.com/thoughtbot/factory_bot

### Fixtures

All fixtures should be placed under `spec/fixtures/`.

### Repositories

Testing some functionality, e.g., merging a merge request, requires a Git
repository with a certain state to be present in the test environment. GitLab
maintains the [`gitlab-test`](https://gitlab.com/gitlab-org/gitlab-test)
repository for certain common cases - you can ensure a copy of the repository is
used with the `:repository` trait for project factories:

```ruby
let(:project) { create(:project, :repository) }
```

Where you can, consider using the `:custom_repo` trait instead of `:repository`.
This allows you to specify exactly what files will appear in the `master` branch
of the project's repository. For example:

```ruby
let(:project) do
  create(
    :project, :custom_repo,
    files: {
      'README.md'       => 'Content here',
      'foo/bar/baz.txt' => 'More content here'
    }
  )
end
```

This will create a repository containing two files, with default permissions and
the specified content.

### Config

RSpec config files are files that change the RSpec config (i.e.
`RSpec.configure do |config|` blocks). They should be placed under
`spec/support/`.

Each file should be related to a specific domain, e.g.
`spec/support/capybara.rb`, `spec/support/carrierwave.rb`, etc.

If a helpers module applies only to a certain kind of specs, it should add
modifiers to the `config.include` call. For instance if
`spec/support/helpers/cycle_analytics_helpers.rb` applies to `:lib` and
`type: :model` specs only, you would write the following:

```ruby
RSpec.configure do |config|
  config.include Spec::Support::Helpers::CycleAnalyticsHelpers, :lib
  config.include Spec::Support::Helpers::CycleAnalyticsHelpers, type: :model
end
```

If a config file only consists of `config.include`, you can add these
`config.include` directly in `spec/spec_helper.rb`.

For very generic helpers, consider including them in the `spec/support/rspec.rb`
file which is used by the `spec/fast_spec_helper.rb` file. See
[Fast unit tests](#fast-unit-tests) for more details about the
`spec/fast_spec_helper.rb` file.

---

[Return to Testing documentation](index.md)
