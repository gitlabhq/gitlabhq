# Testing best practices

## Test speed

GitLab has a massive test suite that, without [parallelization], can take hours
to run. It's important that we make an effort to write tests that are accurate
and effective _as well as_ fast.

Here are some things to keep in mind regarding test performance:

- `double` and `spy` are faster than `FactoryBot.build(...)`
- `FactoryBot.build(...)` and `.build_stubbed` are faster than `.create`.
- Don't `create` an object when `build`, `build_stubbed`, `attributes_for`,
  `spy`, or `double` will do. Database persistence is slow!
- Don't mark a feature as requiring JavaScript (through `@javascript` in
  Spinach or `:js` in RSpec) unless it's _actually_ required for the test
  to be valid. Headless browser testing is slow!

[parallelization]: ci.md#test-suite-parallelization-on-the-ci

## RSpec

### General guidelines

- Use a single, top-level `describe ClassName` block.
- Use `.method` to describe class methods and `#method` to describe instance
  methods.
- Use `context` to test branching logic.
- Try to match the ordering of tests to the ordering within the class.
- Try to follow the [Four-Phase Test][four-phase-test] pattern, using newlines
  to separate phases.
- Use `Gitlab.config.gitlab.host` rather than hard coding `'localhost'`
- Don't assert against the absolute value of a sequence-generated attribute (see
  [Gotchas](../gotchas.md#dont-assert-against-the-absolute-value-of-a-sequence-generated-attribute)).
- Don't supply the `:each` argument to hooks since it's the default.
- On `before` and `after` hooks, prefer it scoped to `:context` over `:all`
- When using `evaluate_script("$('.js-foo').testSomething()")` (or `execute_script`) which acts on a given element,
  use a Capyabara matcher beforehand (e.g. `find('.js-foo')`) to ensure the element actually exists.

[four-phase-test]: https://robots.thoughtbot.com/four-phase-test

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

Note: `live_debug` only works on javascript enabled specs.

### Fast unit tests

Some classes are well-isolated from Rails and you should be able to test them
without the overhead added by the Rails environment and Bundler's `:default`
group's gem loading. In these cases, you can `require 'fast_spec_helper'`
instead of `require 'spec_helper'` in your test file, and your test should run
really fast since:

- Gems loading is skipped
- Rails app boot is skipped
- gitlab-shell and Gitaly setup are skipped
- Test repositories setup are skipped

Note that in some cases, you might have to add some `require_dependency 'foo'`
in your file under test since Rails autoloading is not available in these cases.

This shouldn't be a problem since explicitely listing dependencies should be
considered a good practice anyway.

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

### `set` variables

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

  let(:project1) { create(:project) }
  let(:project2) { create(:project) }
  where(:a, :b, :result) do
    1         | 1        | true
    1         | 2        | false
    true      | true     | true
    true      | false    | false
    project1  | project1 | true
    project2  | project2 | true
    project 1 | project2 | false
  end

  with_them do
    it { expect(a == b).to eq(result) }

    it 'is isomorphic' do
      expect(b == a).to eq(result)
    end
  end
end
```

### Matchers

Custom matchers should be created to clarify the intent and/or hide the
complexity of RSpec expectations.They should be placed under
`spec/support/matchers/`. Matchers can be placed in subfolder if they apply to
a certain type of specs only (e.g. features, requests etc.) but shouldn't be if
they apply to multiple type of specs.

#### `have_gitlab_http_status`

Prefer `have_gitlab_http_status` over `have_http_status` because the former
could also show the response body whenever the status mismatched. This would
be very useful whenever some tests start breaking and we would love to know
why without editing the source and rerun the tests.

This is especially useful whenever it's showing 500 internal server error.

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

GitLab uses [factory_bot] as a test fixture replacement.

- Factory definitions live in `spec/factories/`, named using the pluralization
  of their corresponding model (`User` factories are defined in `users.rb`).
- There should be only one top-level factory definition per file.
- FactoryBot methods are mixed in to all RSpec groups. This means you can (and
  should) call `create(...)` instead of `FactoryBot.create(...)`.
- Make use of [traits] to clean up definitions and usages.
- When defining a factory, don't define attributes that are not required for the
  resulting record to pass validation.
- When instantiating from a factory, don't supply attributes that aren't
  required by the test.
- Factories don't have to be limited to `ActiveRecord` objects.
  [See example](https://gitlab.com/gitlab-org/gitlab-ce/commit/0b8cefd3b2385a21cfed779bd659978c0402766d).

[factory_bot]: https://github.com/thoughtbot/factory_bot
[traits]: http://www.rubydoc.info/gems/factory_bot/file/GETTING_STARTED.md#Traits

### Fixtures

All fixtures should be be placed under `spec/fixtures/`.

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
