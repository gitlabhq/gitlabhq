# Best practices when writing end-to-end tests

## Avoid using a GUI when it's not required

The majority of the end-to-end tests require some state to be built in the application for the tests to happen.

A good example is a user being logged in as a pre-condition for testing the feature.

But if the login feature is already covered with end-to-end tests through the GUI, there is no reason to perform such an expensive task to test the functionality of creating a project, or importing a repo, even if these features depend on a user being logged in. Let's see an example to make things clear.

Let's say that, on average, the process to perform a successful login through the GUI takes 2 seconds.

Now, realize that almost all tests need the user to be logged in, and that we need every test to run in isolation, meaning that tests cannot interfere with each other. This would  mean that for every test the user needs to log in, and "waste 2 seconds".

Now, multiply the number of tests per 2 seconds, and as your test suite grows, the time to run it grows with it, and this is not sustainable.

An alternative to perform a login in a cheaper way would be having an endpoint (available only for testing) where we could pass the user's credentials as encrypted values as query strings, and then we would be redirected to the logged in home page if the credentials are valid. Let's say that, on average, this process takes only 200 miliseconds.

You see the point right?

Performing a login through the GUI for every test would cost a lot in terms of tests' execution.

And there is another reason.

Let's say that you don't follow the above suggestion, and depend on the GUI for the creation of every application state in order to test a specific feature. In this case we could be talking about the **Issues** feature, that depends on a project to exist, and the user to be logged in.

What would happen if there was a bug in the project creation page, where the 'Create' button is disabled, not allowing for the creation of a project through the GUI, but the API logic is still working?

In this case, instead of having only the project creation test failing, we would have many tests that depend on a project to be failing too.

But, if we were following the best practices, only one test would be failing, and tests for other features that depend on a project to exist would continue to pass, since they could be creating the project behind the scenes interacting directly with the public APIs, ensuring a more reliable metric of test failure rate.

Finally, interacting with the application only by its GUI generates a higher rate of test flakiness, and we want to avoid that at max.

**The takeaways here are:**

- Building state through the GUI is time consuming and it's not sustainable as the test suite grows.
- When depending only on the GUI to create the application's state and tests fail due to front-end issues, we can't rely on the test failures rate, and we generate a higher rate of test flakiness.

Now that we are aware of all of it, [let's go create some tests](quick_start_guide.md).

## Prefer to split tests across multiple files

Our framework includes a couple of parallelization mechanisms that work by executing spec files in parallel.

However, because tests are parallelized by spec *file* and not by test/example, we can't achieve greater parallelization if a new test is added to an existing file.

Nonetheless, there could be other reasons to add a new test to an existing file.

For example, if tests share state that is expensive to set up it might be more efficient to perform that setup once even if it means the tests that use the setup can't be parallelized.

In summary:

- **Do**: Split tests across separate files, unless the tests share expensive setup.
- **Don't**: Put new tests in an existing file without considering the impact on parallelization.

## Limit the use of `before(:all)` and `after` hooks

Limit the use of `before(:all)` hook to perform setup tasks with only API calls, non UI operations
or basic UI operations such as login.

We use [`capybara-screenshot`](https://github.com/mattheworiordan/capybara-screenshot) library to automatically save screenshots on failures.
This library [saves the screenshots in the RSpec's `after` hook](https://github.com/mattheworiordan/capybara-screenshot/blob/master/lib/capybara-screenshot/rspec.rb#L97).
[If there is a failure in `before(:all)`, the `after` hook is not called](https://github.com/rspec/rspec-core/pull/2652/files#diff-5e04af96d5156e787f28d519a8c99615R148) and so the screenshots are not saved.

Given this fact, we should limit the use of `before(:all)` to only those operations where a screenshot is not
necessary in case of failure and QA logs would be enough for debugging.

Similarly, the `after` hook should only be used for non-UI operations. Any UI operations in `after` hook in a test file
would execute before the `after` hook that takes the screenshot. This would result in moving the UI status away from the
point of failure and so the screenshot would not be captured at the right moment.

## Ensure tests do not leave the browser logged in

All QA tests expect to be able to log in at the start of the test.

That's not possible if a test leaves the browser logged in when it finishes. Normally this isn't a problem because [Capybara resets the session after each test](https://github.com/teamcapybara/capybara/blob/9ebc5033282d40c73b0286e60217515fd1bb0b5d/lib/capybara/rspec.rb#L18). But Capybara does that in an `after` block, so when a test logs in in an `after(:context)` block, the browser returns to a logged in state *after* Capybara had logged it out. And so the next test will fail.

For an example see: <https://gitlab.com/gitlab-org/gitlab/issues/34736>

Ideally, any actions peformed in an `after(:context)` (or [`before(:context)`](#limit-the-use-of-beforeall-and-after-hooks)) block would be performed via the API. But if it's necessary to do so via the UI (e.g., if API functionality doesn't exist), make sure to log out at the end of the block.

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
