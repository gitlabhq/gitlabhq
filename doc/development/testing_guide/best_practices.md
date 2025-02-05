---
stage: none
group: unassigned
info: "See the Technical Writers assigned to Development Guidelines: https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-development-guidelines"
description: "GitLab development guidelines - testing best practices."
title: Testing best practices
---

## Test Design

Testing at GitLab is a first class citizen, not an afterthought. It's important we consider the design of our tests
as we do the design of our features.

When implementing a feature, we think about developing the right capabilities the right way. This helps us
narrow our scope to a manageable level. When implementing tests for a feature, we must think about developing
the right tests, but then cover _all_ the important ways the test may fail. This can quickly widen our scope to
a level that is difficult to manage.

Test heuristics can help solve this problem. They concisely address many of the common ways bugs
manifest themselves in our code. When designing our tests, take time to review known test heuristics to inform
our test design. We can find some helpful heuristics documented in the Handbook in the
[Test Engineering](https://handbook.gitlab.com/handbook/engineering/infrastructure/test-platform/test-engineering/#test-heuristics) section.

## RSpec

To run RSpec tests:

```shell
# run test for a file
bin/rspec spec/models/project_spec.rb

# run test for the example on line 10 on that file
bin/rspec spec/models/project_spec.rb:10

# run tests matching the example name has that string
bin/rspec spec/models/project_spec.rb -e associations

# run all tests, will take hours for GitLab codebase!
bin/rspec

```

Use [Guard](https://github.com/guard/guard) to continuously monitor for changes and only run matching tests:

```shell
bundle exec guard
```

When using spring and guard together, use `SPRING=1 bundle exec guard` instead to make use of spring.

### General guidelines

- Use a single, top-level `RSpec.describe ClassName` block.
- Use `.method` to describe class methods and `#method` to describe instance
  methods.
- Use `context` to test branching logic (`RSpec/AvoidConditionalStatements` RuboCop Cop - [MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117152)).
- Try to match the ordering of tests to the ordering in the class.
- Try to follow the [Four-Phase Test](https://thoughtbot.com/blog/four-phase-test) pattern, using newlines
  to separate phases.
- Use `Gitlab.config.gitlab.host` rather than hard coding `'localhost'`.
- For literal URLs in tests, use `example.com`, `gitlab.example.com`. This will ensure that we do not utilize any real URLs.
- Don't assert against the absolute value of a sequence-generated attribute (see
  [Gotchas](../gotchas.md#do-not-assert-against-the-absolute-value-of-a-sequence-generated-attribute)).
- Avoid using `expect_any_instance_of` or `allow_any_instance_of` (see
  [Gotchas](../gotchas.md#avoid-using-expect_any_instance_of-or-allow_any_instance_of-in-rspec)).
- Don't supply the `:each` argument to hooks because it's the default.
- On `before` and `after` hooks, prefer it scoped to `:context` over `:all`.
- When using `evaluate_script("$('.js-foo').testSomething()")` (or `execute_script`) which acts on a given element,
  use a Capybara matcher beforehand (such as `find('.js-foo')`) to ensure the element actually exists.
- Use `focus: true` to isolate parts of the specs you want to run.
- Use [`:aggregate_failures`](https://rspec.info/features/3-12/rspec-core/expectation-framework-integration/aggregating-failures/) when there is more than one expectation in a test.
- For [empty test description blocks](https://github.com/rubocop-hq/rspec-style-guide#it-and-specify), use `specify` rather than `it do` if the test is self-explanatory.
- Use `non_existing_record_id`/`non_existing_record_iid`/`non_existing_record_access_level`
  when you need an ID/IID/access level that doesn't actually exist. Using 123, 1234,
  or even 999 is brittle as these IDs could actually exist in the database in the
  context of a CI run.

### Eager loading the application code

By default, the application code:

- Isn't eagerly loaded in the `test` environment.
- Is eagerly loaded in CI/CD (when `ENV['CI'].present?`) to surface any potential loading issues.

If you need to enable eager loading when executing tests,
use the `GITLAB_TEST_EAGER_LOAD` environment variable:

```shell
GITLAB_TEST_EAGER_LOAD=1 bin/rspec spec/models/project_spec.rb
```

If your test depends on all the application code that is being loaded, add the `:eager_load` tag.
This ensures that the application code is eagerly loaded before the test execution.

### Ruby warnings

We've enabled [deprecation warnings](https://ruby-doc.org/core-2.7.4/Warning.html)
by default when running specs. Making these warnings more visible to developers
helps upgrading to newer Ruby versions.

You can silence deprecation warnings by setting the environment variable
`SILENCE_DEPRECATIONS`, for example:

```shell
# silence all deprecation warnings
SILENCE_DEPRECATIONS=1 bin/rspec spec/models/project_spec.rb
```

### Test order

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93137) in GitLab 15.4.

All new spec files are run in [random order](https://gitlab.com/gitlab-org/gitlab/-/issues/337399)
to surface flaky tests that are dependent on test order.

When randomized:

- The string `# order random` is added below the example group description.
- The used seed is shown in the spec output below the test suite summary. For example, `Randomized with seed 27443`.

For a list of spec files which are still run in defined order, see [`rspec_order_todo.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/support/rspec_order_todo.yml).

To make spec files run in random order, check their order dependency with:

```shell
scripts/rspec_check_order_dependence spec/models/project_spec.rb
```

If the specs pass the check the script removes them from
[`rspec_order_todo.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/support/rspec_order_todo.yml) automatically.

If the specs fail the check they must be fixed before than can run in random order.

### Test flakiness

[Consult the Unhealthy tests page for more information about processes that are in place to avoid flaky tests](unhealthy_tests.md#flaky-tests).

### Test slowness

GitLab has a massive test suite that, without [parallelization](../pipelines/_index.md#test-suite-parallelization), can take hours
to run. It's important that we make an effort to write tests that are accurate
and effective _as well as_ fast.

Test performance is important to maintaining quality and velocity, and has a
direct impact on CI build times and thus fixed costs. We want thorough, correct,
and fast tests. Here you can find some information about tools and techniques
available to you to achieve that.

[Consult the Unhealthy tests page for more information about processes that are in place to avoid slow tests](unhealthy_tests.md#slow-tests).

#### Don't request capabilities you don't need

We make it easy to add capabilities to our examples by annotating the example or
a parent context. Examples of these are:

- `:js` in feature specs, which runs a full JavaScript capable headless browser.
- `:clean_gitlab_redis_cache` which provides a clean Redis cache to the examples.
- `:request_store` which provides a request store to the examples.

We should reduce test dependencies, and avoiding
capabilities also reduces the amount of set-up needed.

`:js` is particularly important to avoid. This must only be used if the feature
test requires JavaScript reactivity in the browser (for example, clicking a Vue.js component). Using a headless
browser is much slower than parsing the HTML response from the app.

#### Profiling: see where your test spend its time

[`rspec-stackprof`](https://github.com/dkhroad/rspec-stackprof) can be used to generate a flame graph that shows you where you test spend its time.

The gem generates a JSON report that we can upload to <https://www.speedscope.app> for an interactive visualization.

##### Installation

`stackprof` gem is [already installed with GitLab](https://gitlab.com/gitlab-org/gitlab/-/blob/695fcee0c5541b4ead0a90eb9b8bf0b69bee796c/Gemfile#L487), and we also have a script available that generates the JSON report (`bin/rspec-stackprof`).

```shell
# Optional: install the `speedscope` package to easily upload the JSON report to https://www.speedscope.app
npm install -g speedscope
```

##### Generate the JSON report

```shell
bin/rspec-stackprof --speedscope=true <your_slow_spec>
# There will be the name of the report displayed when the script ends.

# Upload the JSON report to speedscope.app
speedscope tmp/<your-json-report>.json
```

##### How to interpret the flamegraph

Below are some useful tips to interpret and navigate the flamegraph:

- There are [several views available](https://github.com/jlfwong/speedscope#views) for the flamegraph. `Left Heavy` is particularly useful when there are a lot of function calls (for example, feature specs).
- You can zoom in or out! See [the navigation documentation](https://github.com/jlfwong/speedscope#navigation)
- If you are working on a slow feature test, search for `Capybara::DSL#` in the search to see the capybara actions that are made, and how long they take!

See [#414929](https://gitlab.com/gitlab-org/gitlab/-/issues/414929#note_1425239887) or [#375004](https://gitlab.com/gitlab-org/gitlab/-/issues/375004#note_1109867718) for some analysis examples.

#### Optimize factory usage

A common cause of slow tests is excessive creation of objects, and thus
computation and DB time. Factories are essential to development, but they can
make inserting data into the DB so easy that we may be able to optimize.

The two basic techniques to bear in mind here are:

- **Reduce**: avoid creating objects, and avoid persisting them.
- **Reuse**: shared objects, especially nested ones we do not examine, can generally be shared.

To avoid creation, it is worth bearing in mind that:

- `instance_double` and `spy` are faster than `FactoryBot.build(...)`.
- `FactoryBot.build(...)` and `.build_stubbed` are faster than `.create`.
- Don't `create` an object when you can use `build`, `build_stubbed`, `attributes_for`,
  `spy`, or `instance_double`. Database persistence is slow!

Use [Factory Doctor](https://test-prof.evilmartians.io/#/profilers/factory_doctor) to find cases where database persistence is not needed in a given test.

Examples of factories optimization [1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106796), [2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105329).

```shell
# run test for path
FDOC=1 bin/rspec spec/[path]/[to]/[spec].rb
```

A common change is to use `build` or `build_stubbed` instead of `create`:

```ruby
# Old
let(:project) { create(:project) }

# New
let(:project) { build(:project) }
```

[Factory Profiler](https://test-prof.evilmartians.io/#/profilers/factory_prof) can help to identify repetitive database persistence via factories.

```shell
# run test for path
FPROF=1 bin/rspec spec/[path]/[to]/[spec].rb

# to visualize with a flamegraph
FPROF=flamegraph bin/rspec spec/[path]/[to]/[spec].rb
```

A common cause of a large number of created factories is [factory cascades](https://github.com/test-prof/test-prof/blob/master/docs/profilers/factory_prof.md#factory-flamegraph), which result when factories create and recreate associations.
They can be identified by a noticeable difference between `total time` and `top-level time` numbers:

```plaintext
   total   top-level     total time      time per call      top-level time               name

     208           0        9.5812s            0.0461s             0.0000s          namespace
     208          76       37.4214s            0.1799s            13.8749s            project
```

The table above shows us that we never create any `namespace` objects explicitly
(`top-level == 0`) - they are all created implicitly for us. But we still end up
with 208 of them (one for each project) and this takes 9.5 seconds.

In order to reuse a single object for all calls to a named factory in implicit parent associations,
[`FactoryDefault`](https://github.com/test-prof/test-prof/blob/master/docs/recipes/factory_default.md)
can be used:

```ruby
RSpec.describe API::Search, factory_default: :keep do
  let_it_be(:namespace) { create_default(:namespace) }
```

Then every project we create uses this `namespace`, without us having to pass
it as `namespace: namespace`. In order to make it work along with `let_it_be`, `factory_default: :keep`
must be explicitly specified. That keeps the default factory for every example in a suite instead of
recreating it for each example.

To prevent accidental reliance between test examples, objects created
with `create_default` are
[frozen](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/support/factory_default.rb).

Maybe we don't need to create 208 different projects - we
can create one and reuse it. In addition, we can see that only about 1/3 of the
projects we create are ones we ask for (76/208). There is benefit in setting
a default value for projects as well:

```ruby
  let_it_be(:project) { create_default(:project) }
```

In this case, the `total time` and `top-level time` numbers match more closely:

```plaintext
   total   top-level     total time      time per call      top-level time               name

      31          30        4.6378s            0.1496s             4.5366s            project
       8           8        0.0477s            0.0477s             0.0477s          namespace
```

##### Let's talk about `let`

There are various ways to create objects and store them in variables in your tests. They are, from least efficient to most efficient:

- `let!` creates the object before each example runs. It also creates a new object for every example. You should only use this option if you need to create a clean object before each example without explicitly referring to it.
- `let` lazily creates the object. It isn't created until the object is called. `let` is generally inefficient as it creates a new object for every example. `let` is fine for simple values. However, more efficient variants of `let` are best when dealing with database models such as factories.
- `let_it_be_with_refind` works similar to `let_it_be_with_reload`, but the [former calls `ActiveRecord::Base#find`](https://github.com/test-prof/test-prof/blob/936b29f87b36f88a134e064aa6d8ade143ae7a13/lib/test_prof/ext/active_record_refind.rb#L15) instead of `ActiveRecord::Base#reload`. `reload` is usually faster than `refind`.
- `let_it_be_with_reload` creates an object one time for all examples in the same context, but after each example, the database changes are rolled back, and `object.reload` will be called to restore the object to its original state. This means you can make changes to the object before or during an example. However, there are cases where [state leaks across other models](https://github.com/test-prof/test-prof/blob/master/docs/recipes/let_it_be.md#state-leakage-detection) can occur. In these cases, `let` may be an easier option, especially if only a few examples exist.
- `let_it_be` creates an object one time for all of the examples in the same context. This is a great alternative to `let` and `let!` for objects that do not need to change from one example to another. Using `let_it_be` can dramatically speed up tests that create database models. See <https://github.com/test-prof/test-prof/blob/master/docs/recipes/let_it_be.md#let-it-be> for more details and examples.

Pro-tip: When writing tests, it is best to consider the objects inside a `let_it_be` as **immutable**, as there are some important caveats when modifying objects inside a `let_it_be` declaration ([1](https://github.com/test-prof/test-prof/blob/master/docs/recipes/let_it_be.md#database-is-rolled-back-to-a-pristine-state-but-the-objects-are-not), [2](https://github.com/test-prof/test-prof/blob/master/docs/recipes/let_it_be.md#modifiers)). To make your `let_it_be` objects immutable, consider using `freeze: true`:

```shell
# Before
let_it_be(:namespace) { create_default(:namespace) }

# After
let_it_be(:namespace, freeze: true) { create_default(:namespace) }
```

See <https://github.com/test-prof/test-prof/blob/master/docs/recipes/let_it_be.md#state-leakage-detection> for more information on `let_it_be` freezing.

`let_it_be` is the most optimized option since it instantiates an object once and shares its instance across examples. If you find yourself needing `let` instead of `let_it_be`, try `let_it_be_with_reload`.

```ruby
# Old
let(:project) { create(:project) }

# New
let_it_be(:project) { create(:project) }

# If you need to expect changes to the object in the test
let_it_be_with_reload(:project) { create(:project) }
```

Here is an example of when `let_it_be` cannot be used, but `let_it_be_with_reload` allows for more efficiency than `let`:

```ruby
let_it_be(:user) { create(:user) }
let_it_be_with_reload(:project) { create(:project) } # The test will fail if `let_it_be` is used

context 'with a developer' do
  before do
    project.add_developer(user)
  end

  it 'project has an owner and a developer' do
    expect(project.members.map(&:access_level)).to match_array([Gitlab::Access::OWNER, Gitlab::Access::DEVELOPER])
  end
end

context 'with a maintainer' do
  before do
    project.add_maintainer(user)
  end

  it 'project has an owner and a maintainer' do
    expect(project.members.map(&:access_level)).to match_array([Gitlab::Access::OWNER, Gitlab::Access::MAINTAINER])
  end
end
```

#### Stubbing methods within factories

You should avoid using `allow(object).to receive(:method)` in factories, as this makes the factory unable to be used with `let_it_be`, as described in [common test setup](#common-test-setup).

Instead, you can use `stub_method` to stub the method:

```ruby
  before(:create) do |user, evaluator|
    # Stub a method.
    stub_method(user, :some_method) { 'stubbed!' }
    # Or with arguments, including named ones
    stub_method(user, :some_method) { |var1| "Returning #{var1}!" }
    stub_method(user, :some_method) { |var1: 'default'| "Returning #{var1}!" }
  end

  # Un-stub the method.
  # This may be useful where the stubbed object is created with `let_it_be`
  # and you want to reset the method between tests.
  after(:create) do  |user, evaluator|
    restore_original_method(user, :some_method)
    # or
    restore_original_methods(user)
  end
```

NOTE:
`stub_method` does not work when used in conjunction with `let_it_be_with_refind`. This is because `stub_method` will stub a method on an instance and `let_it_be_with_refind` will create a new instance of the object for each run.

`stub_method` does not support method existence and method arity checks.

WARNING:
`stub_method` is supposed to be used in factories only. It's strongly discouraged to be used elsewhere. Consider using [RSpec mocks](https://rspec.info/features/3-12/rspec-mocks/) if available.

#### Stubbing member access level

To stub [member access level](../../user/permissions.md#roles) for factory stubs like `Project` or `Group` use
[`stub_member_access_level`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/support/stub_member_access_level.rb):

```ruby
let(:project) { build_stubbed(:project) }
let(:maintainer) { build_stubbed(:user) }
let(:policy) { ProjectPolicy.new(maintainer, project) }

it 'allows admin_project ability' do
  stub_member_access_level(project, maintainer: maintainer)

  expect(policy).to be_allowed(:admin_project)
end
```

NOTE:
Refrain from using this stub helper if the test code relies on persisting
`project_authorizations` or `Member` records. Use `Project#add_member` or `Group#add_member` instead.

#### Additional profiling metrics

We can use the `rspec_profiling` gem to diagnose, for instance, the number of SQL queries we're making when running a test.

This could be caused by some application side SQL queries **triggered by a test that could mock parts that are not under test** (for example, [!123810](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123810)).

[See the instructions in the performance docs](../performance.md#rspec-profiling).

#### Troubleshoot slow feature test

A slow feature test can generally be optimized the same way as any other test. However, there are some specific techniques that can make the troubleshooting session more fruitful.

##### See what the feature test is doing in the UI

```shell
# Before
bin/rspec ./spec/features/admin/admin_settings_spec.rb:992

# After
WEBDRIVER_HEADLESS=0 bin/rspec ./spec/features/admin/admin_settings_spec.rb:992
```

See [Run `:js` spec in a visible browser](#run-js-spec-in-a-visible-browser) for more info.

##### Search for `Capybara::DSL#` when using profiling

<!-- TODO: Add the search keywords -->
When using [`stackprof` flamegraphs](#profiling-see-where-your-test-spend-its-time), search for `Capybara::DSL#` in the search to see the capybara actions that are made, and how long they take!

#### Identify slow tests

Running a spec with profiling is a good way to start optimizing a spec. This can
be done with:

```shell
bundle exec rspec --profile -- path/to/spec_file.rb
```

Which includes information like the following:

```plaintext
Top 10 slowest examples (10.69 seconds, 7.7% of total time):
  Issue behaves like an editable mentionable creates new cross-reference notes when the mentionable text is edited
    1.62 seconds ./spec/support/shared_examples/models/mentionable_shared_examples.rb:164
  Issue relative positioning behaves like a class that supports relative positioning .move_nulls_to_end manages to move nulls to the end, stacking if we cannot create enough space
    1.39 seconds ./spec/support/shared_examples/models/relative_positioning_shared_examples.rb:88
  Issue relative positioning behaves like a class that supports relative positioning .move_nulls_to_start manages to move nulls to the end, stacking if we cannot create enough space
    1.27 seconds ./spec/support/shared_examples/models/relative_positioning_shared_examples.rb:180
  Issue behaves like an editable mentionable behaves like a mentionable extracts references from its reference property
    0.99253 seconds ./spec/support/shared_examples/models/mentionable_shared_examples.rb:69
  Issue behaves like an editable mentionable behaves like a mentionable creates cross-reference notes
    0.94987 seconds ./spec/support/shared_examples/models/mentionable_shared_examples.rb:101
  Issue behaves like an editable mentionable behaves like a mentionable when there are cached markdown fields sends in cached markdown fields when appropriate
    0.94148 seconds ./spec/support/shared_examples/models/mentionable_shared_examples.rb:86
  Issue behaves like an editable mentionable when there are cached markdown fields when the markdown cache is stale persists the refreshed cache so that it does not have to be refreshed every time
    0.92833 seconds ./spec/support/shared_examples/models/mentionable_shared_examples.rb:153
  Issue behaves like an editable mentionable when there are cached markdown fields refreshes markdown cache if necessary
    0.88153 seconds ./spec/support/shared_examples/models/mentionable_shared_examples.rb:130
  Issue behaves like an editable mentionable behaves like a mentionable generates a descriptive back-reference
    0.86914 seconds ./spec/support/shared_examples/models/mentionable_shared_examples.rb:65
  Issue#related_issues returns only authorized related issues for given user
    0.84242 seconds ./spec/models/issue_spec.rb:335

Finished in 2 minutes 19 seconds (files took 1 minute 4.42 seconds to load)
277 examples, 0 failures, 1 pending
```

From this result, we can see the most expensive examples in our spec, giving us
a place to start. The most expensive examples here are in
shared examples; any reductions generally have a larger impact as
they are called in multiple places.

#### Avoid repeating expensive actions

While isolated examples are very clear, and help serve the purpose of specs as
specification, the following example shows how we can combine expensive
actions:

```ruby
subject { described_class.new(arg_0, arg_1) }

it 'creates an event' do
  expect { subject.execute }.to change(Event, :count).by(1)
end

it 'sets the frobulance' do
  expect { subject.execute }.to change { arg_0.reset.frobulance }.to('wibble')
end

it 'schedules a background job' do
  expect(BackgroundJob).to receive(:perform_async)

  subject.execute
end
```

If the call to `subject.execute` is expensive, then we are repeating the same
action just to make different assertions. We can reduce this repetition by
combining the examples:

```ruby
it 'performs the expected side-effects' do
  expect(BackgroundJob).to receive(:perform_async)

  expect { subject.execute }
    .to change(Event, :count).by(1)
    .and change { arg_0.frobulance }.to('wibble')
end
```

Be careful doing this, as this sacrifices clarity and test independence for
performance gains.

When combining tests, consider using `:aggregate_failures`, so that the full
results are available, and not just the first failure.

#### In case you're stuck

We have a `backend_testing_performance` [domain expertise](https://handbook.gitlab.com/handbook/engineering/workflow/code-review/#domain-experts) to list people that could help refactor slow backend specs.

To find people that could help, search for `backend testing performance` on the [Engineering Projects page](https://handbook.gitlab.com/handbook/engineering/projects/), or look directly in [the `www-gitlab-org` project](https://gitlab.com/search?group_id=6543&nav_source=navbar&project_id=7764&repository_ref=master&scope=blobs&search=backend_testing_performance+path%3Adata%2Fteam_members%2F*&search_code=true).

### Feature category metadata

You must [set feature category metadata for each RSpec example](../feature_categorization/_index.md#rspec-examples).

### Tests depending on EE license

You can use `if: Gitlab.ee?` or `unless: Gitlab.ee?` on context/spec blocks to execute tests depending on whether running with `FOSS_ONLY=1`.

Example: [SchemaValidator reads a different path depending on the license](https://gitlab.com/gitlab-org/gitlab/-/blob/7cdcf9819cfa02c701d6fa9f18c1e7a8972884ed/spec/lib/gitlab/ci/parsers/security/validators/schema_validator_spec.rb#L571)

### Tests depending on SaaS

You can use the `:saas` RSpec metadata tag helper on context/spec blocks to test code that only runs on GitLab.com. This helper sets `Gitlab.config.gitlab['url']` to `Gitlab::Saas.com_url`.

### Coverage

[`simplecov`](https://github.com/colszowka/simplecov) is used to generate code test coverage reports.
These are generated automatically on the CI, but not when running tests locally. To generate partial reports
when you run a spec file on your machine, set the `SIMPLECOV` environment variable:

```shell
SIMPLECOV=1 bundle exec rspec spec/models/repository_spec.rb
```

Coverage reports are generated into the `coverage` folder in the app root, and you can open these in your browser, for example:

```shell
firefox coverage/index.html
```

Use the coverage reports to ensure your tests cover 100% of your code.

### System / Feature tests

NOTE:
Before writing a new system test,
[consider this guide around their use](testing_levels.md#white-box-tests-at-the-system-level-formerly-known-as-system--feature-tests)

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
- It's ok to look for DOM elements, but don't abuse it, because it makes the tests
  more brittle

#### UI testing

When testing the UI, write tests that simulate what a user sees and how they interact with the UI.
This means preferring Capybara's semantic methods and avoiding querying by IDs, classes, or attributes.

The benefits of testing in this way are that:

- It ensures all interactive elements have an [accessible name](../fe_guide/accessibility/best_practices.md#provide-accessible-names-for-screen-readers).
- It is more readable, as it uses more natural language.
- It is less brittle, as it avoids querying by IDs, classes, and attributes, which are not visible to the user.

We strongly recommend that you query by the element's text label instead of by ID, class name, or `data-testid`.

If needed, you can scope interactions within a specific area of the page by using `within`.
As you will likely be scoping to an element such as a `div`, which typically does not have a label,
you may use a `data-testid` selector in this case.

You can use the `be_axe_clean` matcher to run [axe automated accessibility testing](../fe_guide/accessibility/automated_testing.md) in feature tests.

##### Externalized contents

For RSpec tests, expectations against externalized contents should call the same
externalizing method to match the translation. For example, you should use the `_`
method in Ruby.

See [Internationalization for GitLab - Test files (RSpec)](../i18n/externalization.md#test-files-rspec) for details.

##### Actions

Where possible, use more specific [actions](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara/Node/Actions), such as the ones below.

```ruby
# good
click_button _('Submit review')

click_link _('UI testing docs')

fill_in _('Search projects'), with: 'gitlab' # fill in text input with text

select _('Updated date'), from: 'Sort by' # select an option from a select input

check _('Checkbox label')
uncheck _('Checkbox label')

choose _('Radio input label')

attach_file(_('Attach a file'), '/path/to/file.png')

# bad - interactive elements must have accessible names, so
# we should be able to use one of the specific actions above
find('.group-name', text: group.name).click
find('.js-show-diff-settings').click
find('[data-testid="submit-review"]').click
find('input[type="checkbox"]').click
find('.search').native.send_keys('gitlab')
```

##### Finders

Where possible, use more specific [finders](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara/Node/Finders), such as the ones below.

```ruby
# good
find_button _('Submit review')
find_button _('Submit review'), disabled: true

find_link _('UI testing docs')
find_link _('UI testing docs'), href: docs_url

find_field _('Search projects')
find_field _('Search projects'), with: 'gitlab' # find the input field with text
find_field _('Search projects'), disabled: true
find_field _('Checkbox label'), checked: true
find_field _('Checkbox label'), unchecked: true

# acceptable when finding a element that is not a button, link, or field
find_by_testid('element')
```

##### Matchers

Where possible, use more specific [matchers](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara/RSpecMatchers), such as the ones below.

```ruby
# good
expect(page).to have_button _('Submit review')
expect(page).to have_button _('Submit review'), disabled: true
expect(page).to have_button _('Notifications'), class: 'is-checked' # assert the "Notifications" GlToggle is checked

expect(page).to have_link _('UI testing docs')
expect(page).to have_link _('UI testing docs'), href: docs_url # assert the link has an href

expect(page).to have_field _('Search projects')
expect(page).to have_field _('Search projects'), disabled: true
expect(page).to have_field _('Search projects'), with: 'gitlab' # assert the input field has text

expect(page).to have_checked_field _('Checkbox label')
expect(page).to have_unchecked_field _('Radio input label')

expect(page).to have_select _('Sort by')
expect(page).to have_select _('Sort by'), selected: 'Updated date' # assert the option is selected
expect(page).to have_select _('Sort by'), options: ['Updated date', 'Created date', 'Due date'] # assert an exact list of options
expect(page).to have_select _('Sort by'), with_options: ['Created date', 'Due date'] # assert a partial list of options

expect(page).to have_text _('Some paragraph text.')
expect(page).to have_text _('Some paragraph text.'), exact: true # assert exact match

expect(page).to have_current_path 'gitlab/gitlab-test/-/issues'

expect(page).to have_title _('Not Found')

# acceptable when a more specific matcher above is not possible
expect(page).to have_css 'h2', text: 'Issue title'
expect(page).to have_css 'p', text: 'Issue description', exact: true
expect(page).to have_css '[data-testid="weight"]', text: 2
expect(page).to have_css '.atwho-view ul', visible: true
```

##### Interacting with modals

Use the `within_modal` helper to interact with [GitLab UI modals](https://gitlab-org.gitlab.io/gitlab-ui/?path=/story/base-modal--default).

```ruby
include Spec::Support::Helpers::ModalHelpers

within_modal do
  expect(page).to have_link _('UI testing docs')

  fill_in _('Search projects'), with: 'gitlab'

  click_button 'Continue'
end
```

Furthermore, you can use `accept_gl_confirm` for confirmation modals that only need to be accepted.
This is helpful when migrating [`window.confirm()`](https://developer.mozilla.org/en-US/docs/Web/API/Window/confirm) to [`confirmAction`](https://gitlab.com/gitlab-org/gitlab/-/blob/ee280ed2b763d1278ad38c6e7e8a0aff092f617a/app/assets/javascripts/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal.js#L3).

```ruby
include Spec::Support::Helpers::ModalHelpers

accept_gl_confirm do
  click_button 'Delete user'
end
```

You can also pass the expected confirmation message and button text to `accept_gl_confirm`.

```ruby
include Spec::Support::Helpers::ModalHelpers

accept_gl_confirm('Are you sure you want to delete this user?', button_text: 'Delete') do
  click_button 'Delete user'
end
```

##### Other useful methods

After you retrieve an element using a [finder method](#finders), you can invoke a number of
[element methods](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara/Node/Element)
on it, such as `hover`.

Capybara tests also have a number of [session methods](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara/Session) available, such as `accept_confirm`.

Some other useful methods are shown below:

```ruby
refresh # refresh the page

send_keys([:shift, 'i']) # press Shift+I keys to go to the Issues dashboard page

current_window.resize_to(1000, 1000) # resize the window

scroll_to(find_field('Comment')) # scroll to an element
```

You can also find a number of GitLab custom helpers in the `spec/support/helpers/` directory.

#### Live debug

Sometimes you may need to debug Capybara tests by observing browser behavior.

You can pause Capybara and view the website on the browser by using the
`live_debug` method in your spec. The current page is automatically opened
in your default browser.
You may need to sign in first (the current user's credentials are displayed in
the terminal).

To resume the test run, press any key.

For example:

```shell
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

`live_debug` only works on JavaScript enabled specs.

#### Run `:js` spec in a visible browser

Run the spec with `WEBDRIVER_HEADLESS=0`, like this:

```shell
WEBDRIVER_HEADLESS=0 bin/rspec some_spec.rb
```

The test completes quickly, but this gives you an idea of what's happening.
Using `live_debug` with `WEBDRIVER_HEADLESS=0` pauses the open browser, and does not
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

Some classes are well-isolated from Rails. You should be able to test them
without the overhead added by the Rails environment and Bundler's `:default`
group's gem loading. In these cases, you can `require 'fast_spec_helper'`
instead of `require 'spec_helper'` in your test file, and your test should run
really fast because:

- Gem loading is skipped
- Rails app boot is skipped
- GitLab Shell and Gitaly setup are skipped
- Test repositories setup are skipped

It takes around one second to load tests that are using `fast_spec_helper`
instead of 30+ seconds in case of a regular `spec_helper`.

`fast_spec_helper` also support autoloading classes that are located inside the
`lib/` directory. If your class or module is using only
code from the `lib/` directory, you don't need to explicitly load any
dependencies. `fast_spec_helper` also loads all ActiveSupport extensions,
including core extensions that are commonly used in the Rails environment.

Note that in some cases, you might still have to load some dependencies using
`require_dependency` when a code is using gems or a dependency is not located
in `lib/`.

For example, if you want to test your code that is calling the
`Gitlab::UntrustedRegexp` class, which under the hood uses `re2` library, you
should either:

- Add `require_dependency 're2'` to files in your library that need `re2` gem,
  to make this requirement explicit. This approach is preferred.
- Add it to the spec itself.

Alternately, if it is a dependency which is required by many different `fast_spec_helper`
specs in your domain, and you don't want to have to manually add the dependency many
times, you can add it to be called directly from `fast_spec_helper` itself. To do
this, you can create a `spec/support/fast_spec/YOUR_DOMAIN/fast_spec_helper_support.rb`
file, and require it from `fast_spec_helper`. There are existing examples of this
you can follow.

Use `rubocop_spec_helper` for RuboCop related specs.

WARNING:
To verify that code and its specs are well-isolated from Rails, run the spec
individually via `bin/rspec`. Don't use `bin/spring rspec` as it loads
`spec_helper` automatically.

#### Maintaining fast_spec_helper specs

There is a utility script `scripts/run-fast-specs.sh` which can be used to run
all specs which use `fast_spec_helper`, in various ways. This script is useful
to help identify `fast_spec_helper` specs which have problems, such as not
running successfully in isolation. See the script for more details.

### `subject` and `let` variables

The GitLab RSpec suite has made extensive use of `let`(along with its strict, non-lazy
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
  order is required, otherwise `let` suffices. Remember that `let` is lazy and won't
  be evaluated until it is referenced.
- Avoid referencing `subject` in examples. Use a named subject `subject(:name)`, or a `let` variable instead, so
  the variable has a contextual name.
- If the `subject` is never referenced inside examples, then it's acceptable to define the `subject` without a name.

### Common test setup

NOTE:
`let_it_be` and `before_all` do not work with DatabaseCleaner's deletion strategy. This includes migration specs, Rake task specs, and specs that have the `:delete` RSpec metadata tag.
For more information, see [issue 420379](https://gitlab.com/gitlab-org/gitlab/-/issues/420379).

In some cases, there is no need to recreate the same object for tests
again for each example. For example, a project and a guest of that project
are needed to test issues on the same project, so one project and user are enough for the entire file.

As much as possible, do not implement this using `before(:all)` or `before(:context)`. If you do,
you would need to manually clean up the data as those hooks run outside a database transaction.

Instead, this can be achieved by using
[`let_it_be`](https://test-prof.evilmartians.io/#/recipes/let_it_be) variables and the
[`before_all`](https://test-prof.evilmartians.io/#/recipes/before_all) hook
from the [`test-prof` gem](https://rubygems.org/gems/test-prof).

```ruby
let_it_be(:project) { create(:project) }
let_it_be(:user) { create(:user) }

before_all do
  project.add_guest(user)
end
```

This results in only one `Project`, `User`, and `ProjectMember` created for this context.

`let_it_be` and `before_all` are also available in nested contexts. Cleanup after the context
is handled automatically using a transaction rollback.

Note that if you modify an object defined inside a `let_it_be` block,
then you must do one of the following:

- Reload the object as needed.
- Use the `let_it_be_with_reload` alias.
- Specify the `reload` option to reload for every example.

```ruby
let_it_be_with_reload(:project) { create(:project) }
let_it_be(:project, reload: true) { create(:project) }
```

You can also use the `let_it_be_with_refind` alias, or specify the `refind`
option as well to completely load a new object.

```ruby
let_it_be_with_refind(:project) { create(:project) }
let_it_be(:project, refind: true) { create(:project) }
```

Note that `let_it_be` cannot be used with factories that has stubs, such as `allow`.
The reason is that `let_it_be` happens in a `before(:all)` block, and RSpec does not
allow stubs in `before(:all)`.
See this [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/340487) for more details.
To resolve, use `let`, or change the factory to not use stubs.

### `let_it_be` must not depend on a before block

When using `let_it_be` in the middle of a spec, make sure that it does not depend on a `before` block, since the `let_it_be` will be executed first during `before(:all)`.

In [this example](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179302#note_2323774955), `create(:bar)` ran a callback which depended on the stub:

```ruby
let_it_be(:node) { create(:geo_node, :secondary) }

before do
  stub_current_geo_node(node)
end

context 'foo' do
  let_it_be(:bar) { create(:bar) }

  ...
end
```

The stub isn't set when `create(:bar)` executes, so the tests are flaky.

In this example, `before` cannot be replaced with `before_all` because you cannot use doubles or partial doubles from RSpec-mocks outside of the per-test lifecycle.

Therefore, the solution is to use `let` or `let!` instead of `let_it_be(:bar)`.

### Time-sensitive tests

[`ActiveSupport::Testing::TimeHelpers`](https://api.rubyonrails.org/classes/ActiveSupport/Testing/TimeHelpers.html)
can be used to verify things that are time-sensitive. Any test that exercises or verifies something time-sensitive
should make use of these helpers to prevent transient test failures.

Example:

```ruby
it 'is overdue' do
  issue = build(:issue, due_date: Date.tomorrow)

  travel_to(3.days.from_now) do
    expect(issue).to be_overdue
  end
end
```

#### RSpec helpers

You can use the `:freeze_time` and `:time_travel_to` RSpec metadata tag helpers to help reduce the amount of
boilerplate code needed to wrap entire specs with the [`ActiveSupport::Testing::TimeHelpers`](https://api.rubyonrails.org/classes/ActiveSupport/Testing/TimeHelpers.html)
methods.

```ruby
describe 'specs which require time to be frozen', :freeze_time do
  it 'freezes time' do
    right_now = Time.now

    expect(Time.now).to eq(right_now)
  end
end

describe 'specs which require time to be frozen to a specific date and/or time', time_travel_to: '2020-02-02 10:30:45 -0700' do
  it 'freezes time to the specified date and time' do
    expect(Time.now).to eq(Time.new(2020, 2, 2, 17, 30, 45, '+00:00'))
  end
end
```

[Under the hood](https://gitlab.com/gitlab-org/gitlab/-/blob/master/gems/gitlab-rspec/lib/gitlab/rspec/configurations/time_travel.rb), these helpers use the `around(:each)` hook and the block syntax of the
[`ActiveSupport::Testing::TimeHelpers`](https://api.rubyonrails.org/classes/ActiveSupport/Testing/TimeHelpers.html)
methods:

```ruby
around(:each) do |example|
  freeze_time { example.run }
end

around(:each) do |example|
  travel_to(date_or_time) { example.run }
end
```

Remember that any objects created before the examples run (such as objects created via `let_it_be`) will be outside spec scope.
If the time for everything needs to be frozen, `before :all` can be used to encapsulate the setup as well.

```ruby
before :all do
  freeze_time
end

after :all do
  unfreeze_time
end
```

#### Timestamp truncation

Active Record timestamps are [set by the Rails’ `ActiveRecord::Timestamp`](https://github.com/rails/rails/blob/1eb5cc13a2ed8922b47df4ae47faf5f23faf3d35/activerecord/lib/active_record/timestamp.rb#L105)
module [using `Time.now`](https://github.com/rails/rails/blob/1eb5cc13a2ed8922b47df4ae47faf5f23faf3d35/activerecord/lib/active_record/timestamp.rb#L78).
Time precision is [OS-dependent](https://ruby-doc.org/core-2.6.3/Time.html#method-c-new),
and as the docs state, may include fractional seconds.

When Rails models are saved to the database,
any timestamps they have are stored using a type in PostgreSQL called `timestamp without time zone`,
which has microsecond resolution—that is six digits after the decimal.
So if `1577987974.6472975` is sent to PostgreSQL,
it truncates the last digit of the fractional part and instead saves `1577987974.647297`.

The results of this can be a simple test like:

```ruby
let_it_be(:contact) { create(:contact) }

data = Gitlab::HookData::IssueBuilder.new(issue).build

expect(data).to include('customer_relations_contacts' => [contact.hook_attrs])
```

Failing with an error along the lines of:

```shell
expected {
"assignee_id" => nil, "...1 +0000 } to include {"customer_relations_contacts" => [{:created_at => "2023-08-04T13:30:20Z", :first_name => "Sidney Jones3" }]}

Diff:
       @@ -1,35 +1,69 @@
       -"customer_relations_contacts" => [{:created_at=>"2023-08-04T13:30:20Z", :first_name=>"Sidney Jones3" }],
       +"customer_relations_contacts" => [{"created_at"=>2023-08-04 13:30:20.245964000 +0000, "first_name"=>"Sidney Jones3" }],
```

The fix is to ensure we `.reload` the object from the database to get the timestamp with correct precision:

```ruby
let_it_be(:contact) { create(:contact) }

data = Gitlab::HookData::IssueBuilder.new(issue).build

expect(data).to include('customer_relations_contacts' => [contact.reload.hook_attrs])
```

This explanation was taken from [a blog post](https://www.toptal.com/ruby-on-rails/timestamp-truncation-rails-activerecord-tale)
by Maciek Rząsa.

You can see a [merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126530#note_1500580985)
where this problem arose and the [backend pairing session](https://www.youtube.com/watch?v=nMCjEeuYFDA)
where it was discussed.

### Feature flags in tests

This section was moved to [developing with feature flags](../feature_flags/_index.md).

### Pristine test environments

The code exercised by a single GitLab test may access and modify many items of
data. Without careful preparation before a test runs, and cleanup afterward,
a test can change data in a way that affects the behavior of
following tests. This should be avoided at all costs! Fortunately, the existing
test framework handles most cases already.

When the test environment does get polluted, a common outcome is
[flaky tests](unhealthy_tests.md#flaky-tests). Pollution often manifests as an order
dependency: running spec A followed by spec B reliably fails, but running
spec B followed by spec A reliably succeeds. In these cases, you can use
`rspec --bisect` (or a manual pairwise bisect of spec files) to determine which
spec is at fault. Fixing the problem requires some understanding of how the test
suite ensures the environment is pristine. Read on to discover more about each
data store!

#### SQL database

This is managed for us by the `database_cleaner` gem. Each spec is surrounded in
a transaction, which is rolled back after the test completes. Certain specs
instead issue `DELETE FROM` queries against every table after completion. This
allows the created rows to be viewed from multiple database connections, which
is important for specs that run in a browser, or migration specs, among others.

One consequence of using these strategies, instead of the well-known
`TRUNCATE TABLES` approach, is that primary keys and other sequences are **not**
reset across specs. So if you create a project in spec A, then create a project
in spec B, the first has `id=1`, while the second has `id=2`.

This means that specs should **never** rely on the value of an ID, or any other
sequence-generated column. To avoid accidental conflicts, specs should also
avoid manually specifying any values in these kinds of columns. Instead, leave
them unspecified, and look up the value after the row is created.

##### TestProf in migration specs

Because of what is described above, migration specs can't be run inside
a database transaction. Our test suite uses
[TestProf](https://github.com/test-prof/test-prof) to improve the runtime of the
test suite, but `TestProf` uses database transactions to perform these optimizations.
For this reason, we can't use `TestProf` methods in our migration specs.
These are the methods that should not be used and should be replaced with
default RSpec methods instead:

- `let_it_be`: use `let` or `let!` instead.
- `let_it_be_with_reload`: use `let` or `let!` instead.
- `let_it_be_with_refind`: use `let` or `let!` instead.
- `before_all`: use `before` or `before(:all)` instead.

#### Redis

GitLab stores two main categories of data in Redis: cached items, and Sidekiq
jobs. [View the full list of `Gitlab::Redis::Wrapper` descendants](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/redis.rb) that are backed by
a separate Redis instance.

In most specs, the Rails cache is actually an in-memory store. This is replaced
between specs, so calls to `Rails.cache.read` and `Rails.cache.write` are safe.
However, if a spec makes direct Redis calls, it should mark itself with the
`:clean_gitlab_redis_cache`, `:clean_gitlab_redis_shared_state` or
`:clean_gitlab_redis_queues` traits as appropriate.

#### Background jobs / Sidekiq

By default, Sidekiq jobs are enqueued into a jobs array and aren't processed.
If a test queues Sidekiq jobs and need them to be processed, the
`:sidekiq_inline` trait can be used.

The `:sidekiq_might_not_need_inline` trait was added when
[Sidekiq inline mode was changed to fake mode](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/15479)
to all the tests that needed Sidekiq to actually process jobs. Tests with
this trait should be either fixed to not rely on Sidekiq processing jobs, or their
`:sidekiq_might_not_need_inline` trait should be updated to `:sidekiq_inline` if
the processing of background jobs is needed/expected.

The usage of `perform_enqueued_jobs` is useful only for testing delayed mail
deliveries, because our Sidekiq workers aren't inheriting from `ApplicationJob`
/ `ActiveJob::Base`.

#### DNS

DNS requests are stubbed universally in the test suite
(as of [!22368](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22368)), as DNS can
cause issues depending on the developer's local network. There are RSpec labels
available in `spec/support/dns.rb` which you can apply to tests if you need to
bypass the DNS stubbing, like this:

```ruby
it "really connects to Prometheus", :permit_dns do
```

And if you need more specific control, the DNS blocking is implemented in
`spec/support/helpers/dns_helpers.rb` and these methods can be called elsewhere.

#### Rate Limiting

[Rate limiting](../../security/rate_limits.md) is enabled in the test suite. Rate limits
may be triggered in feature specs that use the `:js` trait. In most cases, triggering rate
limiting can be avoided by marking the spec with the `:clean_gitlab_redis_rate_limiting`
trait. This trait clears the rate limiting data stored in Redis cache between specs. If
a single test triggers the rate limit, the `:disable_rate_limit` can be used instead.

#### Stubbing File methods

In the situations where you need to
[stub](https://rspec.info/features/3-12/rspec-mocks/basics/allowing-messages/)
the contents of a file use the `stub_file_read`, and
`expect_file_read` helper methods which handle the stubbing for
`File.read` correctly. These methods stub `File.read` for the given
filename, and also stub `File.exist?` to return `true`.

If you need to manually stub `File.read` for any reason be sure to:

1. Stub and call the original implementation for other file paths.
1. Then stub `File.read` for only the file path you are interested in.

Otherwise `File.read` calls from other parts of the codebase get
stubbed incorrectly.

```ruby
# bad, all Files will read and return nothing
allow(File).to receive(:read)

# good
stub_file_read(my_filepath, content: "fake file content")

# also OK
allow(File).to receive(:read).and_call_original
allow(File).to receive(:read).with(my_filepath).and_return("fake file_content")
```

#### File system

File system data can be roughly split into "repositories", and "everything else".
Repositories are stored in `tmp/tests/repositories`. This directory is emptied
before a test run starts, and after the test run ends. It is not emptied between
specs, so created repositories accumulate in this directory over the
lifetime of the process. Deleting them is expensive, but this could lead to
pollution unless carefully managed.

To avoid this, [hashed storage](../../administration/repository_storage_paths.md)
is enabled in the test suite. This means that repositories are given a unique
path that depends on their project's ID. Because the project IDs are not reset
between specs, each spec gets its own repository on disk,
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
project, or any of its groups. The default path includes the project ID, so it
does not conflict. If two specs create a `:legacy_storage` project with the same
path, they use the same repository on disk and lead to test environment
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
global variables. Don't modify them unless you have to! In particular, prefer
using expectations, or dependency injection along with stubs, to avoid the need
for modifications. If you have no other choice, an `around` block like the global
variables example can be used, but avoid this if at all possible.

#### Elasticsearch specs

Specs that require Elasticsearch must be marked with the `:elastic` trait. This
creates and deletes indices before and after all examples.

The `:elastic_delete_by_query` trait was added to reduce runtime for pipelines by creating and deleting indices at the
start and end of each context only. The [Elasticsearch delete by query API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete-by-query.html)
is used to delete data in all indices (except the migrations index) between examples to ensure a clean index.

The `:elastic_clean` trait creates and deletes indices between examples to ensure a clean index. This way, tests are not
polluted with non-essential data. If using the `:elastic` or `:elastic_delete_by_query` trait
is causing issues, use `:elastic_clean` instead. `:elastic_clean` is significantly slower than the other traits
and should be used sparingly.

Most tests for Elasticsearch logic relate to:

- Creating data in PostgreSQL and waiting for it to be indexed in Elasticsearch.
- Searching for that data.
- Ensuring that the test gives the expected result.

There are some exceptions, such as checking for structural changes rather than individual records in an index.

NOTE:
Elasticsearch indexing uses [`Gitlab::Redis::SharedState`](../redis.md#gitlabrediscachesharedstatequeues).
Therefore, the Elasticsearch traits dynamically use the `:clean_gitlab_redis_shared_state` trait.
You do not need to add `:clean_gitlab_redis_shared_state` manually.

Specs using Elasticsearch require that you:

- Create data in PostgreSQL and then index it into Elasticsearch.
- Enable Application Settings for Elasticsearch (which is disabled by default).

To do so, use:

```ruby
before do
  stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
end
```

Additionally, you can use the `ensure_elasticsearch_index!` method to overcome the asynchronous nature of Elasticsearch.
It uses the [Elasticsearch Refresh API](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-refresh.html#refresh-api-desc)
to make sure all operations performed on an index since the last refresh are available for search. This method is typically
called after loading data into PostgreSQL to ensure the data is indexed and searchable.

You can use the `SEARCH_SPEC_BENCHMARK` environment variable to benchmark test setup steps:

```console
SEARCH_SPEC_BENCHMARK=1 bundle exec rspec ee/spec/lib/elastic/latest/merge_request_class_proxy_spec.rb
```

#### Test Legacy Snowplow events

This section describes how to test with events that have yet to convert to
[internal events](../internal_analytics/internal_event_instrumentation/quick_start.md).

##### Backend

WARNING:
Snowplow performs **runtime type checks** by using the [contracts gem](https://rubygems.org/gems/contracts).
Because Snowplow is **by default disabled in tests and development**, it can be hard to
**catch exceptions** when mocking `Gitlab::Tracking`.

To catch runtime errors due to type checks you can use `expect_snowplow_event`, which checks for
calls to `Gitlab::Tracking#event`.

```ruby
describe '#show' do
  it 'tracks snowplow events' do
    get :show

    expect_snowplow_event(
      category: 'Experiment',
      action: 'start',
      namespace: group,
      project: project
    )
    expect_snowplow_event(
      category: 'Experiment',
      action: 'sent',
      property: 'property',
      label: 'label',
      namespace: group,
      project: project
    )
  end
end
```

When you want to ensure that no event got called, you can use `expect_no_snowplow_event`.

```ruby
  describe '#show' do
    it 'does not track any snowplow events' do
      get :show

      expect_no_snowplow_event(category: described_class.name, action: 'some_action')
    end
  end
```

Even though `category` and `action` can be omitted, you should at least
specify a `category` to avoid flaky tests. For example,
`Users::ActivityService` may track a Snowplow event after an API
request, and `expect_no_snowplow_event` will fail if that happens to run
when no arguments are specified.

##### View layer with data attributes

If you are using the data attributes to register tracking at the Haml layer,
you can use the `have_tracking` matcher method to assert if expected data attributes are assigned.

For example, if we need to test the below Haml,

```haml
%div{ data: { testid: '_testid_', track_action: 'render', track_label: '_tracking_label_' } }
```

- [RSpec view specs](https://rspec.info/features/6-0/rspec-rails/view-specs/view-spec/)

```ruby
    it 'assigns the tracking items' do
      render

      expect(rendered).to have_tracking(action: 'render', label: '_tracking_label_', testid: '_testid_')
    end
```

- [ViewComponent](https://viewcomponent.org/) specs

```ruby
  it 'assigns the tracking items' do
    render_inline(component)

    expect(page).to have_tracking(action: 'render', label: '_tracking_label_', testid: '_testid_')
  end
```

When you want to ensure that tracking isn't assigned, you can use `not_to` with the above matchers.

#### Test Snowplow context against the schema

The [Snowplow schema matcher](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60480)
helps to reduce validation errors by testing Snowplow context against the JSON schema.
The schema matcher accepts the following parameters:

- `schema path`
- `context`

To add a schema matcher spec:

1. Add a new schema to the [Iglu repository](https://gitlab.com/gitlab-org/iglu),
   then copy the same schema to the `spec/fixtures/product_intelligence/` directory.
1. In the copied schema, remove the `"$schema"` key and value. We do not need it for specs
   and the spec fails if we keep the key, as it tries to look for the schema in the URL.
1. Use the following snippet to call the schema matcher:

   ```ruby
   match_snowplow_context_schema(schema_path: '<filename from step 1>', context: <Context Hash> )
   ```

### Table-based / Parameterized tests

This style of testing is used to exercise one piece of code with a comprehensive
range of inputs. By specifying the test case once, alongside a table of inputs
and the expected output for each, your tests can be made easier to read and more
compact.

We use the [RSpec::Parameterized](https://github.com/tomykaira/rspec-parameterized)
gem. A short example, using the table syntax and checking Ruby equality for a
range of inputs, might look like this:

```ruby
describe "#==" do
  using RSpec::Parameterized::TableSyntax

  let(:one) { 1 }
  let(:two) { 2 }

  where(:a, :b, :result) do
    1         | 1         | true
    1         | 2         | false
    true      | true      | true
    true      | false     | false
    ref(:one) | ref(:one) | true  # let variables must be referenced using `ref`
    ref(:one) | ref(:two) | false
  end

  with_them do
    it { expect(a == b).to eq(result) }

    it 'is isomorphic' do
      expect(b == a).to eq(result)
    end
  end
end
```

If, after creating a table-based test, you see an error that looks like this:

```ruby
NoMethodError:
  undefined method `to_params'

  param_sets = extracted.is_a?(Array) ? extracted : extracted.to_params
                                                                       ^^^^^^^^^^
  Did you mean?  to_param
```

That indicates that you need to include the line `using RSpec::Parameterized::TableSyntax` in the spec file.

<!-- vale gitlab_base.Spelling = NO -->

WARNING:
Only use simple values as input in the `where` block. Using procs, stateful
objects, FactoryBot-created objects, and similar items can lead to
[unexpected results](https://github.com/tomykaira/rspec-parameterized/issues/8).

<!-- vale gitlab_base.Spelling = YES -->

### Prometheus tests

Prometheus metrics may be preserved from one test run to another. To ensure that metrics are
reset before each example, add the `:prometheus` tag to the RSpec test.

### Matchers

Custom matchers should be created to clarify the intent and/or hide the
complexity of RSpec expectations. They should be placed under
`spec/support/matchers/`. Matchers can be placed in subfolder if they apply to
a certain type of specs only (such as features or requests) but shouldn't be if
they apply to multiple type of specs.

#### `be_like_time`

Time returned from a database can differ in precision from time objects
in Ruby, so we need flexible tolerances when comparing in specs.

The PostgreSQL time and timestamp types
have [the resolution of 1 microsecond](https://www.postgresql.org/docs/current/datatype-datetime.html).
However, the precision of Ruby `Time` can vary [depending on the OS.](https://blog.paulswartz.net/post/142749676062/ruby-time-precision-os-x-vs-linux)

Consider the following snippet:

```ruby
project = create(:project)

expect(project.created_at).to eq(Project.find(project.id).created_at)
```

On Linux, `Time` can have the maximum precision of 9 and
`project.created_at` has a value (like `2023-04-28 05:53:30.808033064`) with the same precision.
However, the actual value `created_at` (like `2023-04-28 05:53:30.808033`) stored to and loaded from the database
doesn't have the same precision, and the match would fail.
On macOS X, the precision of `Time` matches that of the PostgreSQL timestamp type
 and the match could succeed.

To avoid the issue, we can use `be_like_time` or `be_within` to compare
that times are within one second of each other.

Example:

```ruby
expect(metrics.merged_at).to be_like_time(time)
```

Example for `be_within`:

```ruby
expect(violation.reload.merged_at).to be_within(0.00001.seconds).of(merge_request.merged_at)
```

#### `have_gitlab_http_status`

Prefer `have_gitlab_http_status` over `have_http_status` and
`expect(response.status).to` because the former
could also show the response body whenever the status mismatched. This would
be very useful whenever some tests start breaking and we would love to know
why without editing the source and rerun the tests.

This is especially useful whenever it's showing 500 internal server error.

Prefer named HTTP status like `:no_content` over its numeric representation
`206`. See a list of [supported status codes](https://github.com/rack/rack/blob/f2d2df4016a906beec755b63b4edfcc07b58ee05/lib/rack/utils.rb#L490).

Example:

```ruby
expect(response).to have_gitlab_http_status(:ok)
```

#### `match_schema` and `match_response_schema`

The `match_schema` matcher allows validating that the subject matches a
[JSON schema](https://json-schema.org/). The item inside `expect` can be
a JSON string or a JSON-compatible data structure.

`match_response_schema` is a convenience matcher for using with a
response object. from a [request spec](testing_levels.md#integration-tests).

Examples:

```ruby
# Matches against spec/fixtures/api/schemas/prometheus/additional_metrics_query_result.json
expect(data).to match_schema('prometheus/additional_metrics_query_result')

# Matches against ee/spec/fixtures/api/schemas/board.json
expect(data).to match_schema('board', dir: 'ee')

# Matches against a schema made up of Ruby data structures
expect(data).to match_schema(Atlassian::Schemata.build_info)
```

#### `be_valid_json`

`be_valid_json` allows validating that a string parses as JSON and gives
a non-empty result. To combine it with the schema matching above, use
`and`:

```ruby
expect(json_string).to be_valid_json

expect(json_string).to be_valid_json.and match_schema(schema)
```

#### `be_one_of(collection)`

The inverse of `include`, tests that the `collection` includes the expected
value:

```ruby
expect(:a).to be_one_of(%i[a b c])
expect(:z).not_to be_one_of(%i[a b c])
```

### Testing query performance

Testing query performance allows us to:

- Assert that N+1 problems do not exist in a block of code.
- Ensure that the number of queries in a block of code does not increase unnoticed.

#### QueryRecorder

`QueryRecorder` allows profiling and testing of the number of database queries
performed in a given block of code.

See the [`QueryRecorder`](../database/query_recorder.md) section for more details.

#### GitalyClient

`Gitlab::GitalyClient.get_request_count` allows tests of the number of Gitaly queries
made by a given block of code:

See the [`Gitaly Request Counts`](../gitaly.md#request-counts) section for more details.

### Shared contexts

Shared contexts only used in one spec file can be declared inline.
Any shared contexts used by more than one spec file:

- Should be placed under `spec/support/shared_contexts/`.
- Can be placed in subfolder if they apply to a certain type of specs only
  (such as features or requests) but shouldn't be if they apply to multiple type of specs.

Each file should include only one context and have a descriptive name, such as
`spec/support/shared_contexts/controllers/githubish_import_controller_shared_context.rb`.

### Shared examples

Shared examples only used in one spec file can be declared inline.
Any shared examples used by more than one spec file:

- Should be placed under `spec/support/shared_examples/`.
- Can be placed in subfolder if they apply to a certain type of specs only
  (such as features or requests) but shouldn't be if they apply to multiple type of specs.

Each file should include only one context and have a descriptive name, such as
`spec/support/shared_examples/controllers/githubish_import_controller_shared_example.rb`.

### Helpers

Helpers are usually modules that provide some methods to hide the complexity of
specific RSpec examples. You can define helpers in RSpec files if they're not
intended to be shared with other specs. Otherwise, they should be placed
under `spec/support/helpers/`. Helpers can be placed in a subfolder if they apply
to a certain type of specs only (such as features or requests) but shouldn't be
if they apply to multiple type of specs.

Helpers should follow the Rails naming / namespacing convention, where
`spec/support/helpers/` is the root. For instance
`spec/support/helpers/features/iteration_helpers.rb` should define:

```ruby
# frozen_string_literal: true

module Features
  module IterationHelpers
    def iteration_period(iteration)
      "#{iteration.start_date.to_fs(:medium)} - #{iteration.due_date.to_fs(:medium)}"
    end
  end
end
```

Helpers should not change the RSpec configuration. For instance, the helpers module
described above should not include:

```ruby
# bad
RSpec.configure do |config|
  config.include Features::IterationHelpers
end

# good, include in specific spec
RSpec.describe 'Issue Sidebar', feature_category: :team_planning do
  include Features::IterationHelpers
end
```

### Testing Ruby constants

When testing code that uses Ruby constants, focus the test on the behavior that depends on the constant,
rather than testing the values of the constant.

For example, the following is preferred because it tests the behavior of the class method `.categories`.

```ruby
  describe '.categories' do
    it 'gets CE unique category names' do
      expect(described_class.categories).to include(
        'deploy_token_packages',
        'user_packages',
        # ...
        'kubernetes_agent'
      )
    end
  end
```

On the other hand, testing the value of the constant itself, often only repeats the values
in the code and the test, which provides little value.

```ruby
  describe CATEGORIES do
  it 'has values' do
    expect(CATEGORIES).to eq([
                            'deploy_token_packages',
                            'user_packages',
                            # ...
                            'kubernetes_agent'
                             ])
  end
end
```

In critical cases where an error on a constant could have a catastrophic impact,
testing the constant values might be useful as an added safeguard. For example,
if it could bring down the entire GitLab service, cause a customer to be billed more than they should be,
or [cause the universe to implode](../contributing/verify/_index.md#do-not-cause-our-universe-to-implode).

### Factories

GitLab uses [`factory_bot`](https://github.com/thoughtbot/factory_bot) as a test fixture replacement.

- Factory definitions live in `spec/factories/`, named using the pluralization
  of their corresponding model (`User` factories are defined in `users.rb`).
- There should be only one top-level factory definition per file.
- FactoryBot methods are mixed in to all RSpec groups. This means you can (and
  should) call `create(...)` instead of `FactoryBot.create(...)`.
- Make use of [traits](https://www.rubydoc.info/gems/factory_bot/file/GETTING_STARTED.md#traits) to clean up definitions and usages.
- When defining a factory, don't define attributes that are not required for the
  resulting record to pass validation.
- When instantiating from a factory, don't supply attributes that aren't
  required by the test.
- Use [implicit](https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#implicit-definition),
  [explicit](https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#explicit-definition), or
  [inline](https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#inline-definition) associations
  instead of `create` / `build` for association setup in callbacks.
  See [issue #262624](https://gitlab.com/gitlab-org/gitlab/-/issues/262624) for further context.

  When creating factories with a [`has_many`](https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#has_many-associations) and `belongs_to` association, use the `instance` method to refer to the object being built.
  This prevents [creation of unnecessary records](https://gitlab.com/gitlab-org/gitlab/-/issues/378183) by using [interconnected associations](https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#interconnected-associations).

  For example, if we have the following classes:

  ```ruby
  class Car < ApplicationRecord
    has_many :wheels, inverse_of: :car, foreign_key: :car_id
  end

  class Wheel < ApplicationRecord
    belongs_to :car, foreign_key: :car_id, inverse_of: :wheel, optional: false
  end
  ```

  We can create the following factories:

  ```ruby
  FactoryBot.define do
    factory :car do
      transient do
        wheels_count { 2 }
      end

      wheels do
        Array.new(wheels_count) do
          association(:wheel, car: instance)
        end
      end
    end
  end

  FactoryBot.define do
    factory :wheel do
      car { association :car }
    end
  end
  ```

- Factories don't have to be limited to `ActiveRecord` objects.
  [See example](https://gitlab.com/gitlab-org/gitlab-foss/commit/0b8cefd3b2385a21cfed779bd659978c0402766d).
- Factories and their traits should produce valid objects that are [verified by shared specs](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/support/shared_examples/models/factories_shared_examples.rb) run in every model spec.
- Avoid the use of [`skip_callback`](https://api.rubyonrails.org/classes/ActiveSupport/Callbacks/ClassMethods.html#method-i-skip_callback) in factories.
  See [issue #247865](https://gitlab.com/gitlab-org/gitlab/-/issues/247865) for details.

### Fixtures

All fixtures should be placed under `spec/fixtures/`.

### Repositories

Testing some functionality, such as merging a merge request, requires a Git
repository with a certain state to be present in the test environment. GitLab
maintains the [`gitlab-test`](https://gitlab.com/gitlab-org/gitlab-test)
repository for certain common cases - you can ensure a copy of the repository is
used with the `:repository` trait for project factories:

```ruby
let(:project) { create(:project, :repository) }
```

Where you can, consider using the `:custom_repo` trait instead of `:repository`.
This allows you to specify exactly what files appear in the `main` branch
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

This creates a repository containing two files, with default permissions and
the specified content.

### Configuration

RSpec configuration files are files that change the RSpec configuration (like
`RSpec.configure do |config|` blocks). They should be placed under
`spec/support/`.

Each file should be related to a specific domain, such as
`spec/support/capybara.rb` or `spec/support/carrierwave.rb`.

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

If a configuration file only consists of `config.include`, you can add these
`config.include` directly in `spec/spec_helper.rb`.

For very generic helpers, consider including them in the `spec/support/rspec.rb`
file which is used by the `spec/fast_spec_helper.rb` file. See
[Fast unit tests](#fast-unit-tests) for more details about the
`spec/fast_spec_helper.rb` file.

### Test environment logging

Services for the test environment are automatically configured and started when
tests are run, including Gitaly, Workhorse, Elasticsearch, and Capybara. When run in CI, or
if the service needs to be installed, the test environment logs information
about set-up time, producing log messages like the following:

```plaintext
==> Setting up Gitaly...
    Gitaly set up in 31.459649 seconds...

==> Setting up GitLab Workhorse...
    GitLab Workhorse set up in 29.695619 seconds...
fatal: update refs/heads/diff-files-symlink-to-image: invalid <newvalue>: 8cfca84
From https://gitlab.com/gitlab-org/gitlab-test
 * [new branch]      diff-files-image-to-symlink -> origin/diff-files-image-to-symlink
 * [new branch]      diff-files-symlink-to-image -> origin/diff-files-symlink-to-image
 * [new branch]      diff-files-symlink-to-text -> origin/diff-files-symlink-to-text
 * [new branch]      diff-files-text-to-symlink -> origin/diff-files-text-to-symlink
   b80faa8..40232f7  snippet/multiple-files -> origin/snippet/multiple-files
 * [new branch]      testing/branch-with-#-hash -> origin/testing/branch-with-#-hash

==> Setting up GitLab Elasticsearch Indexer...
    GitLab Elasticsearch Indexer set up in 26.514623 seconds...
```

This information is omitted when running locally and when no action needs
to be performed. If you would always like to see these messages, set the
following environment variable:

```shell
GITLAB_TESTING_LOG_LEVEL=debug
```

---

[Return to Testing documentation](_index.md)
