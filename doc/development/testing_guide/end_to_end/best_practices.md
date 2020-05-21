# End-to-end testing Best Practices

NOTE: **Note:**
This is an tailored extension of the Best Practices [found in the testing guide](../best_practices.md).

## Prefer API over UI

The end-to-end testing framework has the ability to fabricate its resources on a case-by-case basis.
Resources should be fabricated via the API wherever possible.

We can save both time and money by fabricating resources that our test will need via the API.

[Learn more](resources.md) about resources.

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
issue = Resource::Issue.fabricate_via_api! do |issue|
  issue.name = 'issue-name'
end

Project::Issues::Index.perform do |index|
  expect(index).to have_issue(issue)
end

#=> Bad
issue = Resource::Issue.fabricate_via_api! do |issue|
  issue.name = 'issue-name'
end

Project::Issues::Index.perform do |index|
  expect(index).to have_issue(issue)
  expect(page).to have_content(issue.name) #=> page content check is redundant as the issue was already validated in the line above.
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

All tests expect to be able to log in at the start of the test.

For an example see: <https://gitlab.com/gitlab-org/gitlab/-/issues/34736>

Ideally, any actions performed in an `after(:context)` (or [`before(:context)`](#limit-the-use-of-the-ui-in-beforecontext-and-after-hooks)) block would be performed via the API. But if it's necessary to do so via the UI (e.g., if API functionality doesn't exist), make sure to log out at the end of the block.

```ruby
after(:all) do
  login unless Page::Main::Menu.perform(&:signed_in?)

  # Do something while logged in

  Page::Main::Menu.perform(&:sign_out)
end
```

## Tag tests that require Administrator access

We don't run tests that require Administrator access against our Production environments.

When you add a new test that requires Administrator access, apply the RSpec metadata `:requires_admin` so that the test will not be included in the test suites executed against Production and other environments on which we don't want to run those tests.

Note: When running tests locally or configuring a pipeline, the environment variable `QA_CAN_TEST_ADMIN_FEATURES` can be set to `false` to skip tests that have the `:requires_admin` tag.

## Prefer `Commit` resource over `ProjectPush`

In line with [using the API](#prefer-api-over-ui), use a `Commit` resource whenever possible.

`ProjectPush` uses raw shell commands via the Git Command Line Interface (CLI) whereas the `Commit` resource makes an HTTP request.

```ruby
# Using a commit resource
Resource::Commit.fabricate_via_api! do |commit|
  commit.commit_message = 'Initial commit'
  commit.add_files([
    {file_path: 'README.md', content: 'Hello, GitLab'}
  ])
end

# Using a ProjectPush
Resource::Repository::ProjectPush.fabricate! do |push|
  push.commit_message = 'Initial commit'
  push.file_name = 'README.md'
  push.file_content = 'Hello, GitLab'
end
```

NOTE: **Note:**
A few exceptions for using a `ProjectPush` would be when your test calls for testing SSH integration or
using the Git CLI.
