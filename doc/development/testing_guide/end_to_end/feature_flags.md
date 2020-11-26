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

CAUTION: **Caution:**
You are strongly advised to [enable feature flags only for a group, project, user](../../feature_flags/development.md#feature-actors),
or [feature group](../../feature_flags/development.md#feature-groups). This makes it possible to
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

Please see the [QA README](https://gitlab.com/gitlab-org/gitlab/tree/master/qa#running-tests-with-a-feature-flag-enabled)
for details.
