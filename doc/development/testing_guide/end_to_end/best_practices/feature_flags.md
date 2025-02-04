---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Testing with feature flags
---

To run a specific test with a feature flag enabled you can use the `QA::Runtime::Feature` class to
enable and disable feature flags ([via the API](../../../../api/features.md)).

Note that administrator authorization is required to change feature flags. `QA::Runtime::Feature`
automatically authenticates as an administrator as long as you provide an appropriate access
token via `GITLAB_QA_ADMIN_ACCESS_TOKEN` (recommended), or provide `GITLAB_ADMIN_USERNAME`
and `GITLAB_ADMIN_PASSWORD`.

## `feature_flag` RSpec tag

Be sure to include the `feature_flag` tag so that the test can be skipped on the appropriate environments.

**Required metadata:**

`name`

- Format: `feature_flag: { name: 'feature_flag_name' }`
- Used for informational purposes. It shall be included to determine which
  feature flag is under test.

**Optional metadata:**

`scope`

- Format: `feature_flag: { name: 'feature_flag_name', scope: :project }`
- When `scope` is set to `:global`, the test will be **skipped on all live .com environments**. This is to avoid issues with feature flag changes affecting other tests or users on that environment.
- When `scope` is set to any other value (such as `:project`, `:group` or `:user`), or if no `scope` is specified, the test will only be **skipped on canary, production, and pre-production**.
  This is due to the fact that administrator access is not available there.

**WARNING:** You are strongly advised to first try and [enable feature flags only for a group, project, user](../../../feature_flags/_index.md#feature-actors),
or [feature group](../../../feature_flags/_index.md#feature-groups).

- If a global feature flag must be used, it is strongly recommended to apply `scope: :global` to the `feature_flag` metadata. This is, however, left up to the SET's discretion to determine the level of risk.
  - For example, a test uses a global feature flag that only affects a small area of the application and is also needed to check for critical issues on live environments.
    In such a scenario, it would be riskier to skip running the test. For cases like this, `scope` can be left out of the metadata so that it can still run in live environments
    with administrator access, such as staging.

**Note on `requires_admin`:** This tag should still be applied if there are other actions within the test that require administrator access that are unrelated to updating a
feature flag (like creating a user via the API).

The code below would enable a feature flag named `:feature_flag_name` for the project
created by the test:

```ruby
RSpec.describe "with feature flag enabled", feature_flag: {
  name: 'feature_flag_name',
  scope: :project
  } do

  let(:project) { Resource::Project.fabricate_via_api! }

  around do |example|
    Runtime::Feature.enable(:feature_flag_name, project: project)
    example.run
    Runtime::Feature.disable(:feature_flag_name, project: project)
  end

  it "feature flag test" do
    # Execute the test with the feature flag enabled.
    # It will only affect the project created in this test.
  end
end
```

Note that the `enable` and `disable` methods first set the flag and then check that the updated
value is returned by the API.

Similarly, you can enable a feature for a group, user, or feature group:

```ruby
group = Resource::Group.fabricate_via_api!
Runtime::Feature.enable(:feature_flag_name, group: group)

user = Resource::User.fabricate_via_api!
Runtime::Feature.enable(:feature_flag_name, user: user)

feature_group = "a_feature_group"
Runtime::Feature.enable(:feature_flag_name, feature_group: feature_group)
```

If no scope is provided, the feature flag is set instance-wide:

```ruby
# This will affect all users!
Runtime::Feature.enable(:feature_flag_name)
```

## Working with selectors

A new feature often replaces a `vue` component or a `haml` file with a new one.
In most cases, the new file or component is accessible only with a feature flag.
This approach becomes problematic when tests must pass both with, and without,
the feature flag enabled. To ensure tests pass in both scenarios:

1. Create another selector inside the new component or file.
1. Give it the same name as the old one.

Selectors are connected to a specific frontend file in the [page object](../beginners_guide/page_objects.md),
and checked for availability inside our `qa:selectors` test. If the mentioned selector
is missing inside that frontend file, the test fails. To ensure selectors are
available when a feature flag is enabled or disabled, add the new selector to the
[page object](../beginners_guide/page_objects.md), leaving the old selector in place.
The test uses the correct selector and still detects missing selectors.

If a new feature changes an existing frontend file that already has a selector,
you can add a new selector with the same name. However, only one of the selectors
displays on the page. You should:

1. Disable the other with the feature flag.
1. Add a comment in the frontend file to delete the old selector from the frontend
   file and from the page object file when the feature flag is removed.

### Example before

```ruby
# This is the link to the old file
view 'app/views/devise/passwords/edit.html.haml' do
  # The new selector should have the same name
  element 'password-field'
  ...
end
```

### Example after

```ruby
view 'app/views/devise/passwords/edit.html.haml' do
  element 'password-field'
  ...
end

# Now it can verify the selector is available
view 'app/views/devise/passwords/new_edit_behind_ff.html.haml' do
  # The selector has the same name
  element 'password-field'
end
```

## Working with resource classes

If a resource class must behave differently when a feature flag is active, toggle a
variable with the name of the feature flag inside the class. This variable and condition
ensure all actions are handled appropriately.

You can set this variable inside the `fabricate_via_api` call. For a consistent approach:

- Use an `activated` check, not a deactivated one.
- Add the word `activated` to the end of a variable's name.
- Inside the `initialize` method, set the variable's default value.

For example:

```ruby
def initialize
  name_of_the_feature_flag_activated = false
  ...
end
```

### Cleanup

After the feature flag is removed, clean up the resource class and delete the variable.
All methods should use the condition procedures of the now-default state.

## Managing flakiness due to caching

All application settings, and all feature flags, are cached inside GitLab for one minute.
All caching is disabled during testing, except on static environments.

When a test changes a feature flag, it can cause flaky behavior if elements are visible only with an
active feature flag. To circumvent this behavior, add a wait for elements behind a feature flag.

## Running a scenario with a feature flag enabled

It's also possible to run an entire scenario with a feature flag enabled, without having to edit
existing tests or write new ones.

See the [QA README](https://gitlab.com/gitlab-org/gitlab/-/tree/master/qa#running-tests-with-a-feature-flag-enabled)
for details.

## Confirming that end-to-end tests pass with a feature flag enabled

End-to-end tests should pass with a feature flag enabled before it is enabled on Staging or on GitLab.com. Tests that need to be updated should be identified as part of [quad-planning](https://handbook.gitlab.com/handbook/engineering/infrastructure/test-platform/quad-planning/). The relevant [counterpart Software Engineer in Test](https://handbook.gitlab.com/handbook/engineering/quality/#individual-contributors) is responsible for updating the tests or assisting another engineer to do so. However, if a change does not go through quad-planning and a required test update is not made, test failures could block deployment.

### Automatic test execution when a feature flag definition changes

There are two ways to confirm that end-to-end tests pass:

- If a merge request adds or edits a [feature flag definition file](../../../feature_flags/_index.md#feature-flag-definition-and-validation),
  two `e2e:test-on-omnibus` jobs (`ee:instance-parallel` and `ee:instance-parallel-ff-inverse`) are included automatically in the merge request pipeline.
  One job runs the application with default feature flag state and another sets it to inverse value. The jobs execute the same suite of tests to confirm that they pass with the feature flag either enabled or disabled.
- In some cases, if end-to-end test jobs didn't trigger automatically, or if it has run the tests with the default feature flag values (which might not be desired),
  you can create a Draft MR that enables the feature flag to ensure that all E2E tests pass with the feature flag enabled and disabled.

### Troubleshooting end-to-end test failures with feature flag enabled

If enabling the feature flag results in E2E test failures, you can browse the artifacts in the failed pipeline to see screenshots of the failed tests. After which, you can either:

- Identify tests that need to be updated and contact the relevant [counterpart Software Engineer in Test](https://handbook.gitlab.com/handbook/engineering/quality/#individual-contributors) responsible for updating the tests or assisting another engineer to do so. However, if a change does not go through [quad-planning](https://handbook.gitlab.com/handbook/engineering/infrastructure/test-platform/quad-planning/) and a required test update is not made, test failures could block deployment.
- Run the failed tests [locally](https://gitlab.com/gitlab-org/gitlab/-/tree/master/qa#run-the-end-to-end-tests-in-a-local-development-environment)
  with the [feature flag enabled](https://gitlab.com/gitlab-org/gitlab/-/tree/master/qa#running-tests-with-a-feature-flag-enabled-or-disabled).
  This option requires considerable amount of setup, but you'll be able to see what the browser is doing as it's running the failed
  tests, which can help debug the problem faster. You can also refer to the [Troubleshooting Guide for E2E tests](../troubleshooting.md) for
  support for common blockers.

### Test execution during feature development

If an end-to-end test enables a feature flag, the end-to-end test suite can be used to test changes in a merge request
by running the `e2e:test-on-omnibus` job in the merge request pipeline. If the feature flag and relevant changes have already been merged, you can confirm that the tests
pass on the default branch. The end-to-end tests run on the default branch every two hours, and the results are posted to a
[Test Session Report, which is available in the testcase-sessions project](https://gitlab.com/gitlab-org/quality/testcase-sessions/-/issues?label_name%5B%5D=found%3Amain).

If the relevant tests do not enable the feature flag themselves, you can check if the tests will need to be updated by opening
a draft merge request that enables the flag by default via a [feature flag definition file](../../../feature_flags/_index.md#feature-flag-definition-and-validation).
That will [automatically execute the end-to-end test suite](#automatic-test-execution-when-a-feature-flag-definition-changes).
The merge request can be closed once the tests pass. If you need assistance to update the tests, contact the relevant [stable counterpart in the Quality department](https://handbook.gitlab.com/handbook/engineering/quality/#individual-contributors), or any Software Engineer in Test if there is no stable counterpart for your group.
