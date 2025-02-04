---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: End-to-end testing Best Practices
---

This is a tailored extension of the Best Practices [found in the testing guide](../../best_practices.md).

## Class and module naming

The QA framework uses [Zeitwerk](https://github.com/fxn/zeitwerk) for class and module autoloading. The default Zeitwerk [inflector](https://github.com/fxn/zeitwerk#zeitwerkinflector) converts snake_cased filenames to PascalCased module or class names. It is advised to stick to this pattern to avoid manual maintenance of inflections.

In case custom inflection logic is needed, custom inflectors are added in the [qa.rb](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/qa.rb) file in the `loader.inflector.inflect` method invocation.

## Link a test to its test case

Every test should have a corresponding test case in the [GitLab project test cases](https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases) as well as a results issue in the [Quality Test Cases project](https://gitlab.com/gitlab-org/quality/testcases/-/issues).
If a test case issue does not yet exist, any GitLab team member can create a new test case in
the **[CI/CD > Test cases](https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases)** page of the GitLab project
with a placeholder title. After the test case URL is linked to a test in the code, when the test is
run in a pipeline that has reporting enabled, the `report-results` script automatically updates the
test case and the results issue.
If a results issue does not yet exist, the `report-results` script automatically creates one and
links it to its corresponding test case.

To link a test case to a test in the code, you must manually add a `testcase` RSpec metadata tag.
In most cases, a single test is associated with a single test case.

For example:

```ruby
RSpec.describe 'Stage' do
  describe 'General description of the feature under test' do
    it 'test name', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/:test_case_id' do
      ...
    end

    it 'another test', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/:another_test_case_id' do
      ...
    end
  end
end
```

### For shared tests

Most tests are defined by a single line of a `spec` file, which is why those tests can be linked to a
single test case via the `testcase` tag.

However, some tests don't have a one-to-one relationship between a line of a `spec` file and a test case.
This is because some tests are defined in a way that means a single line is associated with
multiple tests, including:

- Parallelized tests.
- Templated tests.
- Tests in shared examples that include more than one example.

In those and similar cases we need to include the test case link by other means.

To illustrate, there are two tests in the shared examples in [`qa/specs/features/ee/browser_ui/3_create/repository/restrict_push_protected_branch_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/qa/specs/features/ee/browser_ui/3_create/repository/restrict_push_protected_branch_spec.rb):

```ruby
RSpec.shared_examples 'unselected maintainer' do |testcase|
  it 'user fails to push', testcase: testcase do
    ...
  end
end

RSpec.shared_examples 'selected developer' do |testcase|
  it 'user pushes and merges', testcase: testcase do
    ...
  end
end
```

Consider the following test that includes the shared examples:

```ruby
RSpec.describe 'Create' do
  describe 'Restricted protected branch push and merge' do
    context 'when only one user is allowed to merge and push to a protected branch' do
      ...

      it_behaves_like 'unselected maintainer', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347775'
      it_behaves_like 'selected developer', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347774'
    end

    context 'when only one group is allowed to merge and push to a protected branch' do
      ...

      it_behaves_like 'unselected maintainer', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347772'
      it_behaves_like 'selected developer', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347773'
    end
  end
end
```

We recommend creating four associated test cases, two for each shared example.

## Test naming

Test names should form a readable sentence defining the purpose of the test. Our [testing guide](_index.md) extends the [Thoughtbot testing style guide](https://github.com/thoughtbot/guides/tree/master/testing-rspec). This page clarifies the guidelines, along with input from [https://www.betterspecs.org/](https://www.betterspecs.org/) and [the RSpec naming guide](https://rspec.rubystyle.guide/#naming.)

### Recommended approach

The following block generates a test named `Plan wiki content creation in a project adds a home page`

``` ruby
# `RSpec.describe` is the DevOps Stage being covered
RSpec.describe 'Plan', product_group: :knowledge do
  # `describe` is the feature being tested
  describe 'wiki content creation' do
    # `context` provides the condition being covered
    context 'in a project'
      # `it` defines the expected result of the test
      it 'adds a home page'
      ...
      end
    ...
    end
  ...
  end
end
```

1. Every `describe`, `context`, and `it` blocks should have a short description attached
1. Keep descriptions as concise as possible.
   1. Long descriptions or multiple conditionals could be a sign it should be split up (additional `context` blocks).
   1. The [Documentation Style Guide](../../../documentation/styleguide/_index.md) gives recommendations on how to write concisely and with [active voice](../../../documentation/styleguide/_index.md#active-voice).
1. The outermost `Rspec.describe` block should be [the DevOps stage name](https://handbook.gitlab.com/handbook/product/categories/#devops-stages)
1. Inside the `Rspec.describe` block is a `describe` block with the name of the feature being tested
1. Optional `context` blocks define what the conditions being tested are
   1. `context` blocks descriptions should begin with `when`, `with`, `without`, `for`, `and`, `on`, `in`, `as`, or `if` to match the [RuboCop rule](https://www.rubydoc.info/gems/rubocop-rspec/RuboCop/Cop/RSpec/ContextWording)
1. The `it` block describes the pass/fail criteria for the test
   1. In `shared_examples` with a single example a `specify` block can be used instead of a named `it` block

## Prefer API over UI

The end-to-end testing framework has the ability to fabricate its resources on a case-by-case basis.
Resources should be fabricated via the API wherever possible.

We can save both time and money by fabricating resources that our test will need via the API.

[Learn more](../beginners_guide/resources.md) about resources.

## Avoid superfluous expectations

To keep tests lean, it is important that we only test what we need to test.

Ensure that you do not add any `expect()` statements that are unrelated to what needs to be tested.

For example:

```ruby
#=> Good
Flow::Login.sign_in
Page::Main::Menu.perform do |menu|
  expect(menu).to be_signed_in
end

#=> Bad
Flow::Login.sign_in(as: user)
Page::Main::Menu.perform do |menu|
  expect(menu).to be_signed_in
  expect(page).to have_content(user.name) #=>  we already validated being signed in. redundant.
  expect(menu).to have_element(:nav_bar) #=> likely unnecessary. already validated in lower-level. test doesn't call for validating this.
end

#=> Good
issue = create(:issue, name: 'issue-name')

Project::Issues::Index.perform do |index|
  expect(index).to have_issue(issue)
end

#=> Bad
issue = create(:issue, name: 'issue-name')

Project::Issues::Index.perform do |index|
  expect(index).to have_issue(issue)
  expect(page).to have_content(issue.name) #=> page content check is redundant as the issue was already validated in the line above.
end
```

## Prefer `aggregate_failures` when there are back-to-back expectations

See [Prefer aggregate failures when there are multiple expectations](#prefer-aggregate_failures-when-there-are-multiple-expectations)

## Prefer `aggregate_failures` when there are multiple expectations

In cases where there must be multiple expectations within a test case, it is preferable to use `aggregate_failures`.

This allows you to group a set of expectations and see all the failures altogether, rather than having the test being aborted on the first failure.

For example:

```ruby
#=> Good
Page::Search::Results.perform do |search|
  search.switch_to_code

  aggregate_failures 'testing search results' do
    expect(search).to have_file_in_project(template[:file_name], project.name)
    expect(search).to have_file_with_content(template[:file_name], content[0..33])
  end
end

#=> Bad
Page::Search::Results.perform do |search|
  search.switch_to_code
  expect(search).to have_file_in_project(template[:file_name], project.name)
  expect(search).to have_file_with_content(template[:file_name], content[0..33])
end
```

Attach the `:aggregate_failures` metadata to the example if multiple expectations are separated by statements.

```ruby
#=> Good
it 'searches', :aggregate_failures do
  Page::Search::Results.perform do |search|
    expect(search).to have_file_in_project(template[:file_name], project.name)

    search.switch_to_code

    expect(search).to have_file_with_content(template[:file_name], content[0..33])
  end
end

#=> Bad
it 'searches' do
  Page::Search::Results.perform do |search|
    expect(search).to have_file_in_project(template[:file_name], project.name)

    search.switch_to_code

    expect(search).to have_file_with_content(template[:file_name], content[0..33])
  end
end
```

## Avoid multiple actions in `expect do ... raise_error` blocks

When you wrap multiple actions in a single `expect do ... end.not_to raise_error` or `expect do ... end.to raise_error` block,
it can be hard to debug the actual cause of the failure, because of how the logs are printed. Important information can be truncated
or missing altogether.

For example, if you encapsulate some actions and expectations in a private method in the test, like `expect_owner_permissions_allow_delete_issue`:

```ruby
it "has Owner role with Owner permissions" do
  Page::Dashboard::Projects.perform do |projects|
    projects.filter_by_name(project.name)

    expect(projects).to have_project_with_access_role(project.name, 'Owner')
  end

  expect_owner_permissions_allow_delete_issue
end
```

Then, in the method itself:

```ruby
#=> Good
def expect_owner_permissions_allow_delete_issue
  issue.visit!

  Page::Project::Issue::Show.perform(&:delete_issue)

  Page::Project::Issue::Index.perform do |index|
    expect(index).not_to have_issue(issue)
  end
end

#=> Bad
def expect_owner_permissions_allow_delete_issue
  expect do
    issue.visit!

    Page::Project::Issue::Show.perform(&:delete_issue)

    Page::Project::Issue::Index.perform do |index|
      expect(index).not_to have_issue(issue)
    end
  end.not_to raise_error
end
```

## Prefer to split tests across multiple files

Our framework includes a couple of parallelization mechanisms that work by executing spec files in parallel.

However, because tests are parallelized by spec *file* and not by test/example, we can't achieve greater parallelization if a new test is added to an existing file.

Nonetheless, there could be other reasons to add a new test to an existing file.

For example, if tests share state that is expensive to set up it might be more efficient to perform that setup once even if it means the tests that use the setup can't be parallelized.

In summary:

- **Do**: Split tests across separate files, unless the tests share expensive setup.
- **Don't**: Put new tests in an existing file without considering the impact on parallelization.

## `let` variables vs instance variables

By default, follow the [testing best practices](../../best_practices.md#subject-and-let-variables) when using `let`
or instance variables. However, in end-to-end tests, set-ups such as creating resources are expensive.
If you use `let` to store a resource, it will be created for each example separately.
If the resource can be shared among multiple examples, use an instance variable in the `before(:all)`
block instead of `let` to save run time.
When the variable cannot be shared by multiple examples, use `let`.

## Limit the use of the UI in `before(:context)` and `after` hooks

Limit the use of `before(:context)` hooks to perform setup tasks with only API calls,
non-UI operations, or basic UI operations such as login.

We use [`capybara-screenshot`](https://github.com/mattheworiordan/capybara-screenshot) library to automatically save a screenshot on
failure.

`capybara-screenshot` [saves the screenshot in the RSpec's `after` hook](https://github.com/mattheworiordan/capybara-screenshot/blob/master/lib/capybara-screenshot/rspec.rb#L97).
[If there is a failure in `before(:context)`, the `after` hook is not called](https://github.com/rspec/rspec-core/pull/2652/files#diff-5e04af96d5156e787f28d519a8c99615R148) and so the screenshot is not saved.

Given this fact, we should limit the use of `before(:context)` to only those operations where a screenshot is not needed.

Similarly, the `after` hook should only be used for non-UI operations. Any UI operations in `after` hook in a test file
would execute before the `after` hook that takes the screenshot. This would result in moving the UI status away from the
point of failure and so the screenshot would not be captured at the right moment.

## Ensure tests do not leave the browser logged in

All tests expect to be able to sign in at the start of the test.

For an example see [issue #34736](https://gitlab.com/gitlab-org/gitlab/-/issues/34736).

Ideally, actions performed in an `after(:context)` (or
[`before(:context)`](#limit-the-use-of-the-ui-in-beforecontext-and-after-hooks))
block are performed using the API. If it's necessary to do so with the user
interface (for example, if API functionality doesn't exist), be sure to sign
out at the end of the block.

```ruby
after(:all) do
  login unless Page::Main::Menu.perform(&:signed_in?)

  # Do something while logged in

  Page::Main::Menu.perform(&:sign_out)
end
```

## Tag tests that require administrator access

We don't run tests that require administrator access against our Production environments.

When you add a new test that requires administrator access, apply the RSpec metadata `:requires_admin` so that the test will not be included in the test suites executed against Production and other environments on which we don't want to run those tests.

When running tests locally or configuring a pipeline, the environment variable `QA_CAN_TEST_ADMIN_FEATURES` can be set to `false` to skip tests that have the `:requires_admin` tag.

NOTE:
If the _only_ action in the test that requires administrator access is to toggle a feature flag, use the `feature_flag` tag instead. More details can be found in [testing with feature flags](feature_flags.md).

## Prefer `Commit` resource over `ProjectPush`

In line with [using the API](#prefer-api-over-ui), use a `Commit` resource whenever possible.

`ProjectPush` uses raw shell commands from the Git command-line interface (CLI), and the `Commit` resource makes an HTTP request.

```ruby
# Using a commit resource
Resource::Repository::Commit.fabricate_via_api! do |commit|
  commit.commit_message = 'Initial commit'
  commit.add_files([
    { file_path: 'README.md', content: 'Hello, GitLab' }
  ])
end

# Using a ProjectPush
Resource::Repository::ProjectPush.fabricate! do |push|
  push.commit_message = 'Initial commit'
  push.file_name = 'README.md'
  push.file_content = 'Hello, GitLab'
end
```

A few exceptions for using a `ProjectPush` would be when your test calls for testing SSH integration or
using the Git CLI.

## Preferred method to blur elements

To blur an element, the preferred method is to select another element that does not alter the test state.
If there's a mask that blocks the page elements, such as may occur with some dropdowns,
use WebDriver's native mouse events to simulate a click event on the coordinates of an element. Use the following method: `click_element_coordinates`.

Avoid clicking the `body` for blurring elements such as inputs and dropdowns because it clicks the center of the viewport.
This action can also unintentionally click other elements, altering the test state and causing it to fail.

```ruby
# Clicking another element to blur an input
def add_issue_to_epic(issue_url)
  find_element(:issue_actions_split_button).find('button', text: 'Add an issue').click
  fill_element(:add_issue_input, issue_url)
  # Clicking the title blurs the input
  click_element(:title)
  click_element(:add_issue_button)
end

# Using native mouse click events in the case of a mask/overlay
click_element_coordinates(:title)
```

## Ensure `expect` statements wait efficiently

In general, we use an `expect` statement to check that something _is_ as we expect it. For example:

```ruby
Page::Project::Pipeline::Show.perform do |pipeline|
  expect(pipeline).to have_job('a_job')
end
```

### Use `eventually_` matchers for expectations that require waiting

When something requires waiting to be matched, use `eventually_` matchers with clear wait duration definition.

`Eventually` matchers use the following naming pattern: `eventually_${rspec_matcher_name}`. They are defined in [eventually_matcher.rb](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/qa/support/matchers/eventually_matcher.rb).

```ruby
expect { async_value }.to eventually_eq(value).within(max_duration: 120, max_attempts: 60, reload_page: page)
```

### Create negatable matchers to speed `expect` checks

However, sometimes we want to check that something is _not_ as we _don't_ want it to be. In other
words, we want to make sure something is absent. For unit tests and feature specs,
we commonly use `not_to`
because RSpec's built-in matchers are negatable, as are Capybara's, which means the following two statements are
equivalent.

```ruby
except(page).not_to have_text('hidden')
except(page).to have_no_text('hidden')
```

Unfortunately, that's not automatically the case for the predicate methods that we add to our
[page objects](../beginners_guide/page_objects.md). We need to [create our own negatable matchers](https://rspec.info/features/3-12/rspec-expectations/custom-matchers/define-matcher/).

The initial example uses the `have_job` matcher which is derived from the
[`has_job?` predicate method of the `Page::Project::Pipeline::Show` page object](https://gitlab.com/gitlab-org/gitlab/-/blob/87864b3047c23b4308f59c27a3757045944af447/qa/qa/page/project/pipeline/show.rb#L53).
To create a negatable matcher, we use `has_no_job?` for the negative case:

```ruby
RSpec::Matchers.define :have_job do |job_name|
  match do |page_object|
    page_object.has_job?(job_name)
  end

  match_when_negated do |page_object|
    page_object.has_no_job?(job_name)
  end
end
```

And then the two `expect` statements in the following example are equivalent:

```ruby
Page::Project::Pipeline::Show.perform do |pipeline|
  expect(pipeline).not_to have_job('a_job')
  expect(pipeline).to have_no_job('a_job')
end
```

[See this merge request for a real example of adding a custom matcher](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/46302).

We are creating custom negatable matchers in `qa/spec/support/matchers`.

NOTE:
We need to create custom negatable matchers only for the predicate methods we've added to the test framework, and only if we're using `not_to`. If we use `to have_no_*` a negatable matcher is not necessary but it increases code readability.

### Why we need negatable matchers

Consider the following code, but assume that we _don't_ have a custom negatable matcher for `have_job`.

```ruby
# Bad
Page::Project::Pipeline::Show.perform do |pipeline|
  expect(pipeline).not_to have_job('a_job')
end
```

For this statement to pass, `have_job('a_job')` has to return `false` so that `not_to` can negate it.
The problem is that `have_job('a_job')` waits up to ten seconds for `'a job'` to appear before
returning `false`. Under the expected condition this test will take ten seconds longer than it needs to.

Instead, we could force no wait:

```ruby
# Not as bad but potentially flaky
Page::Project::Pipeline::Show.perform do |pipeline|
  expect(pipeline).not_to have_job('a_job', wait: 0)
end
```

The problem is that if `'a_job'` is present and we're waiting for it to disappear, this statement will fail.

Neither problem is present if we create a custom negatable matcher because the `has_no_job?` predicate method
would be used, which would wait only as long as necessary for the job to disappear.

Lastly, negatable matchers are preferred over using matchers of the form `have_no_*` because it's a common and familiar practice to negate matchers using `not_to`. If we facilitate that practice by adding negatable matchers, we make it easier for subsequent test authors to write efficient tests.

## Use logger over puts

We currently use Rails `logger` to handle logs in both GitLab QA application and end-to-end tests.
This provides additional functionalities when compared with `puts`, such as:

- Ability to specify the logging level.
- Ability to tag similar logs.
- Auto-formatting log messages.
