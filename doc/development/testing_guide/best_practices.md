---
type: reference, dev
stage: none
group: Development
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
description: "GitLab development guidelines - testing best practices."
---

# Testing best practices

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
[Test Engineering](https://about.gitlab.com/handbook/engineering/quality/test-engineering/#test-heuristics) section.

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

### Ruby warnings

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/47767) in GitLab 13.7.

We've enabled [deprecation warnings](https://ruby-doc.org/core-2.7.2/Warning.html)
by default when running specs. Making these warnings more visible to developers
helps upgrading to newer Ruby versions.

You can silence deprecation warnings by setting the environment variable
`SILENCE_DEPRECATIONS`, for example:

```shell
# silence all deprecation warnings
SILENCE_DEPRECATIONS=1 bin/rspec spec/models/project_spec.rb
```

### Test speed

GitLab has a massive test suite that, without [parallelization](ci.md#test-suite-parallelization-on-the-ci), can take hours
to run. It's important that we make an effort to write tests that are accurate
and effective _as well as_ fast.

Test performance is important to maintaining quality and velocity, and has a
direct impact on CI build times and thus fixed costs. We want thorough, correct,
and fast tests. Here you can find some information about tools and techniques
available to you to achieve that.

#### Don't request capabilities you don't need

We make it easy to add capabilities to our examples by annotating the example or
a parent context. Examples of these are:

- `:js` in feature specs, which runs a full JavaScript capable headless browser.
- `:clean_gitlab_redis_cache` which provides a clean Redis cache to the examples.
- `:request_store` which provides a request store to the examples.

We should reduce test dependencies, and avoiding
capabilities also reduces the amount of set-up needed.

`:js` is particularly important to avoid. This must only be used if the feature
test requires JavaScript reactivity in the browser. Using a headless
browser is much slower than parsing the HTML response from the app.

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

A common change is to use [`let_it_be`](#common-test-setup):

```ruby
# Old
let(:project) { create(:project) }

# New
let_it_be(:project) { create(:project) }
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

### General guidelines

- Use a single, top-level `RSpec.describe ClassName` block.
- Use `.method` to describe class methods and `#method` to describe instance
  methods.
- Use `context` to test branching logic.
- Try to match the ordering of tests to the ordering in the class.
- Try to follow the [Four-Phase Test](https://thoughtbot.com/blog/four-phase-test) pattern, using newlines
  to separate phases.
- Use `Gitlab.config.gitlab.host` rather than hard coding `'localhost'`
- Don't assert against the absolute value of a sequence-generated attribute (see
  [Gotchas](../gotchas.md#do-not-assert-against-the-absolute-value-of-a-sequence-generated-attribute)).
- Avoid using `expect_any_instance_of` or `allow_any_instance_of` (see
  [Gotchas](../gotchas.md#do-not-assert-against-the-absolute-value-of-a-sequence-generated-attribute)).
- Don't supply the `:each` argument to hooks because it's the default.
- On `before` and `after` hooks, prefer it scoped to `:context` over `:all`
- When using `evaluate_script("$('.js-foo').testSomething()")` (or `execute_script`) which acts on a given element,
  use a Capybara matcher beforehand (such as `find('.js-foo')`) to ensure the element actually exists.
- Use `focus: true` to isolate parts of the specs you want to run.
- Use [`:aggregate_failures`](https://relishapp.com/rspec/rspec-core/docs/expectation-framework-integration/aggregating-failures) when there is more than one expectation in a test.
- For [empty test description blocks](https://github.com/rubocop-hq/rspec-style-guide#it-and-specify), use `specify` rather than `it do` if the test is self-explanatory.
- Use `non_existing_record_id`/`non_existing_record_iid`/`non_existing_record_access_level`
  when you need an ID/IID/access level that doesn't actually exists. Using 123, 1234,
  or even 999 is brittle as these IDs could actually exist in the database in the
  context of a CI run.

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
Before writing a new system test, [please consider **not**
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
- It's ok to look for DOM elements, but don't abuse it, because it makes the tests
  more brittle

#### UI testing

When testing the UI, write tests that simulate what a user sees and how they interact with the UI.
This means preferring Capybara's semantic methods and avoiding querying by IDs, classes, or attributes.

The benefits of testing in this way are that:

- It ensures all interactive elements have an [accessible name](../fe_guide/accessibility.md#provide-accessible-names-for-screen-readers).
- It is more readable, as it uses more natural language.
- It is less brittle, as it avoids querying by IDs, classes, and attributes, which are not visible to the user.

We strongly recommend that you query by the element's text label instead of by ID, class name, or `data-testid`.

If needed, you can scope interactions within a specific area of the page by using `within`.
As you will likely be scoping to an element such as a `div`, which typically does not have a label,
you may use a `data-testid` selector in this case.

##### Actions

Where possible, use more specific [actions](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara/Node/Actions), such as the ones below.

```ruby
# good
click_button 'Submit review'

click_link 'UI testing docs'

fill_in 'Search projects', with: 'gitlab' # fill in text input with text

select 'Last updated', from: 'Sort by' # select an option from a select input

check 'Checkbox label'
uncheck 'Checkbox label'

choose 'Radio input label'

attach_file('Attach a file', '/path/to/file.png')

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
find_button 'Submit review'
find_button 'Submit review', disabled: true

find_link 'UI testing docs'
find_link 'UI testing docs', href: docs_url

find_field 'Search projects'
find_field 'Search projects', with: 'gitlab' # find the input field with text
find_field 'Search projects', disabled: true
find_field 'Checkbox label', checked: true
find_field 'Checkbox label', unchecked: true

# acceptable when finding a element that is not a button, link, or field
find('[data-testid="element"]')
```

##### Matchers

Where possible, use more specific [matchers](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara/RSpecMatchers), such as the ones below.

```ruby
# good
expect(page).to have_button 'Submit review'
expect(page).to have_button 'Submit review', disabled: true
expect(page).to have_button 'Notifications', class: 'is-checked' # assert the "Notifications" GlToggle is checked

expect(page).to have_link 'UI testing docs'
expect(page).to have_link 'UI testing docs', href: docs_url # assert the link has an href

expect(page).to have_field 'Search projects'
expect(page).to have_field 'Search projects', disabled: true
expect(page).to have_field 'Search projects', with: 'gitlab' # assert the input field has text

expect(page).to have_checked_field 'Checkbox label'
expect(page).to have_unchecked_field 'Radio input label'

expect(page).to have_select 'Sort by'
expect(page).to have_select 'Sort by', selected: 'Last updated' # assert the option is selected
expect(page).to have_select 'Sort by', options: ['Last updated', 'Created date', 'Due date'] # assert an exact list of options
expect(page).to have_select 'Sort by', with_options: ['Created date', 'Due date'] # assert a partial list of options

expect(page).to have_text 'Some paragraph text.'
expect(page).to have_text 'Some paragraph text.', exact: true # assert exact match

expect(page).to have_current_path 'gitlab/gitlab-test/-/issues'

expect(page).to have_title 'Not Found'

# acceptable when a more specific matcher above is not possible
expect(page).to have_css 'h2', text: 'Issue title'
expect(page).to have_css 'p', text: 'Issue description', exact: true
expect(page).to have_css '[data-testid="weight"]', text: 2
expect(page).to have_css '.atwho-view ul', visible: true
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

It takes around one second to load tests that are using `fast_spec_helper`
instead of 30+ seconds in case of a regular `spec_helper`.

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

### Time-sensitive tests

[`ActiveSupport::Testing::TimeHelpers`](https://api.rubyonrails.org/v6.0.3.1/classes/ActiveSupport/Testing/TimeHelpers.html)
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

### Feature flags in tests

This section was moved to [developing with feature flags](../feature_flags/index.md).

### Pristine test environments

The code exercised by a single GitLab test may access and modify many items of
data. Without careful preparation before a test runs, and cleanup afterward,
a test can change data in a way that affects the behavior of
following tests. This should be avoided at all costs! Fortunately, the existing
test framework handles most cases already.

When the test environment does get polluted, a common outcome is
[flaky tests](flaky_tests.md). Pollution often manifests as an order
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
If a test queues Sidekiq jobs and need them to be processed, the
`:sidekiq_inline` trait can be used.

The `:sidekiq_might_not_need_inline` trait was added when [Sidekiq inline mode was
changed to fake mode](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/15479)
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

#### Stubbing File methods

In the situations where you need to
[stub](https://relishapp.com/rspec/rspec-mocks/v/3-9/docs/basics/allowing-messages)
methods such as `File.read`, make sure to:

1. Stub `File.read` for only the file path you are interested in.
1. Call the original implementation for other file paths.

Otherwise `File.read` calls from other parts of the codebase get
stubbed incorrectly. You should use the `stub_file_read`, and
`expect_file_read` helper methods which does the stubbing for
`File.read` correctly.

```ruby
# bad, all Files will read and return nothing
allow(File).to receive(:read)

# good
stub_file_read(my_filepath)

# also OK
allow(File).to receive(:read).and_call_original
allow(File).to receive(:read).with(my_filepath)
```

#### File system

File system data can be roughly split into "repositories", and "everything else".
Repositories are stored in `tmp/tests/repositories`. This directory is emptied
before a test run starts, and after the test run ends. It is not emptied between
specs, so created repositories accumulate in this directory over the
lifetime of the process. Deleting them is expensive, but this could lead to
pollution unless carefully managed.

To avoid this, [hashed storage](../../administration/repository_storage_types.md)
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

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/61171) in GitLab 14.0.

Specs that require Elasticsearch must be marked with the `:elastic` trait. This
creates and deletes indices between examples to ensure a clean index, so that there is no room
for polluting the tests with nonessential data.
Most tests for Elasticsearch logic relate to:

- Creating data in Postgres and waiting for it to be indexed in Elasticsearch.
- Searching for that data.
- Ensuring that the test gives the expected result.

There are some exceptions, such as checking for structural changes rather than individual records in an index.

The `:elastic_with_delete_by_query` trait was added to reduce run time for pipelines by creating and deleting indices
at the start and end of each context only. The [Elasticsearch DeleteByQuery API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete-by-query.html)
is used to delete data in all indices in between examples to ensure a clean index.

Note that Elasticsearch indexing uses [`Gitlab::Redis::SharedState`](../../../ee/development/redis.md#gitlabrediscachesharedstatequeues).
Therefore, the Elasticsearch traits dynamically use the `:clean_gitlab_redis_shared_state` trait.
You do NOT need to add `:clean_gitlab_redis_shared_state` manually.

Specs using Elasticsearch require that you:

- Create data in Postgres and then index it into Elasticsearch.
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
called after loading data into Postgres to ensure the data is indexed and searchable.

#### Test Snowplow events

WARNING:
Snowplow performs **runtime type checks** by using the [contracts gem](https://rubygems.org/gems/contracts).
Because Snowplow is **by default disabled in tests and development**, it can be hard to
**catch exceptions** when mocking `Gitlab::Tracking`.

To catch runtime errors due to type checks, you can enable Snowplow in tests. Mark the spec with
`:snowplow` and use the `expect_snowplow_event` helper, which checks for
calls to `Gitlab::Tracking#event`.

```ruby
describe '#show', :snowplow do
  it 'tracks snowplow events' do
    get :show

    expect_snowplow_event(
      category: 'Experiment',
      action: 'start',
      standard_context: { namespace: group, project: project }
    )
    expect_snowplow_event(
      category: 'Experiment',
      action: 'sent',
      property: 'property',
      label: 'label',
      standard_context: { namespace: group, project: project }
    )
  end
end
```

When you want to ensure that no event got called, you can use `expect_no_snowplow_event`.

```ruby
  describe '#show', :snowplow do
    it 'does not track any snowplow events' do
      get :show

      expect_no_snowplow_event
    end
  end
```

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

WARNING:
Only use simple values as input in the `where` block. Using
<!-- vale gitlab.Spelling = NO --> procs, stateful
objects, FactoryBot-created objects, and similar items can lead to
[unexpected results](https://github.com/tomykaira/rspec-parameterized/issues/8).
<!-- vale gitlab.Spelling = YES -->

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
in Ruby, so we need flexible tolerances when comparing in specs. We can
use `be_like_time` to compare that times are within one second of each
other.

Example:

```ruby
expect(metrics.merged_at).to be_like_time(time)
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
response object. from a [request
spec](testing_levels.md#integration-tests).

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

See the [`QueryRecorder`](../query_recorder.md) section for more details.

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

Helpers should follow the Rails naming / namespacing convention. For instance
`spec/support/helpers/cycle_analytics_helpers.rb` should define:

```ruby
module Spec
  module Support
    module Helpers
      module CycleAnalyticsHelpers
        def create_commit_referencing_issue(issue, branch_name: random_git_name)
          project.repository.add_branch(user, branch_name, 'main')
          create_commit("Commit for ##{issue.iid}", issue.project, user, branch_name)
        end
      end
    end
  end
end
```

Helpers should not change the RSpec configuration. For instance, the helpers module
described above should not include:

```ruby
RSpec.configure do |config|
  config.include Spec::Support::Helpers::CycleAnalyticsHelpers
end
```

### Factories

GitLab uses [factory_bot](https://github.com/thoughtbot/factory_bot) as a test fixture replacement.

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
- Prefer [implicit](https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#implicit-definition)
  or [explicit](https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#explicit-definition)
  association definitions instead of using `create` / `build` for association setup.
  See [issue #262624](https://gitlab.com/gitlab-org/gitlab/-/issues/262624) for further context.
- Factories don't have to be limited to `ActiveRecord` objects.
  [See example](https://gitlab.com/gitlab-org/gitlab-foss/commit/0b8cefd3b2385a21cfed779bd659978c0402766d).
- Factories and their traits should produce valid objects that are [verified by specs](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/factories_spec.rb).

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

[Return to Testing documentation](index.md)
