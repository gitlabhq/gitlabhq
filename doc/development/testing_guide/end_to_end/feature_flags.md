---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Testing with feature flags

To run a specific test with a feature flag enabled you can use the `QA::Runtime::Feature` class to
enable and disable feature flags ([via the API](../../../api/features.md)).

Note that administrator authorization is required to change feature flags. `QA::Runtime::Feature`
automatically authenticates as an administrator as long as you provide an appropriate access
token via `GITLAB_QA_ADMIN_ACCESS_TOKEN` (recommended), or provide `GITLAB_ADMIN_USERNAME`
and `GITLAB_ADMIN_PASSWORD`.

Please be sure to include the tag `:requires_admin` so that the test can be skipped in environments
where admin access is not available.

WARNING:
You are strongly advised to [enable feature flags only for a group, project, user](../../feature_flags/index.md#feature-actors),
or [feature group](../../feature_flags/index.md#feature-groups). This makes it possible to
test a feature in a shared environment without affecting other users.

For example, the code below would enable a feature flag named `:feature_flag_name` for the project
created by the test:

```ruby
RSpec.describe "with feature flag enabled", :requires_admin do
  let(:project) { Resource::Project.fabricate_via_api! }

  before do
    Runtime::Feature.enable(:feature_flag_name, project: project)
  end

  it "feature flag test" do
    # Execute the test with the feature flag enabled.
    # It will only affect the project created in this test.
  end

  after do
    Runtime::Feature.disable(:feature_flag_name, project: project)
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

## Running a scenario with a feature flag enabled

It's also possible to run an entire scenario with a feature flag enabled, without having to edit
existing tests or write new ones.

Please see the [QA README](https://gitlab.com/gitlab-org/gitlab/-/tree/master/qa#running-tests-with-a-feature-flag-enabled)
for details.

## Confirming that end-to-end tests pass with a feature flag enabled

End-to-end tests should pass with a feature flag enabled before it is enabled on Staging or on GitLab.com. Tests that need to be updated should be identified as part of [quad-planning](https://about.gitlab.com/handbook/engineering/quality/quad-planning/). The relevant [counterpart Software Engineer in Test](https://about.gitlab.com/handbook/engineering/quality/#individual-contributors) is responsible for updating the tests or assisting another engineer to do so. However, if a change does not go through quad-planning and a required test update is not made, test failures could block deployment.

If a test enables a feature flag as describe above, it is sufficient to run the `package-and-qa` job in a merge request containing the relevant changes.
Or, if the feature flag and relevant changes have already been merged, you can confirm that the tests
pass on `main`. The end-to-end tests run on `main` every two hours, and the results are posted to a [Test
Session Report, which is available in the testcase-sessions project](https://gitlab.com/gitlab-org/quality/testcase-sessions/-/issues?label_name%5B%5D=found%3Amaster).

If the relevant tests do not enable the feature flag themselves, you can check if the tests will need
to be updated by opening a draft merge request that enables the flag by default and then running the `package-and-qa` job.
The merge request can be closed once the tests pass. If you need assistance to update the tests, please contact the relevant [stable counterpart in the Quality department](https://about.gitlab.com/handbook/engineering/quality/#individual-contributors), or any Software Engineer in Test if there is no stable counterpart for your group.
