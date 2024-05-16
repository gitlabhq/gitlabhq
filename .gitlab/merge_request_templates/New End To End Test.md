## Description of the test

<!--
Please link to the respective test case in the testcases project
-->

## How to set up and validate locally

<!--
In most cases this will be the command to run the test, e.g.:

From the `qa` directory:
```
bundle install
export WEBDRIVER_HEADLESS=false # If you'd like to watch the test in action
export QA_GITLAB_URL="http://gdk.test:3000" # Only needed if GDK is not running on http://127.0.0.1:3000
bundle exec rspec <path/to/spec.rb>
```

This may be particularly helpful if you're requesting reviews from engineers who aren't familiar with GitLab's E2E tests.

Any other necessary setup should be included here as well, especially if it's an orchestrated test that requires a
[special setup](https://docs.gitlab.com/ee/development/testing_guide/end_to_end/running_tests_that_require_special_setup.html)
to run locally against GDK.
-->

### Checklist

- [ ] Confirm the test has a [`testcase:` tag linking to an existing test case](https://docs.gitlab.com/ee/development/testing_guide/end_to_end/best_practices.html#link-a-test-to-its-test-case-issue) in the test case project.
- [ ] Note if the test is intended to run in specific scenarios. If a scenario is new, add a link to the MR that adds the new scenario.
- [ ] Follow the end-to-end tests [style guide](https://docs.gitlab.com/ee/development/testing_guide/end_to_end/style_guide.html) and [best practices](https://docs.gitlab.com/ee/development/testing_guide/end_to_end/best_practices.html).
- [ ] Use the appropriate [RSpec metadata tag(s)](https://docs.gitlab.com/ee/development/testing_guide/end_to_end/rspec_metadata_tests.html#rspec-metadata-for-end-to-end-tests).
- Most resources will be cleaned up via the general [cleanup task](https://gitlab.com/gitlab-org/gitlab/-/blob/44345381e89d6bbd440f7b4c680d03e8b75b86de/qa/qa/tools/test_resources_handler.rb#L44). Check that is successful, or ensure resources are cleaned up in the test:
  - [ ] New resources have `api_get_path` and `api_delete_path` implemented if possible.
  - [ ] If any resource cannot be deleted in the general delete task, make sure it is [ignored](https://gitlab.com/gitlab-org/gitlab/-/blob/44345381e89d6bbd440f7b4c680d03e8b75b86de/qa/qa/tools/test_resources_handler.rb#L29).
  - [ ] If any resource cannot be deleted in the general delete task, remove it in the test (e.g., in an `after` block).
- [ ] Ensure that no [transient bugs](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/#transient-bugs) are hidden accidentally due to the usage of `waits` and `reloads`.
- [ ] Verify the tags to ensure it runs on the desired test environments.
- [ ] If this MR has a dependency on another MR, such as a GitLab QA MR, specify the order in which the MRs should be merged.
- [ ] (If applicable) Create a follow-up issue to document [the special setup](https://docs.gitlab.com/ee/development/testing_guide/end_to_end/running_tests_that_require_special_setup.html) necessary to run the test: ISSUE_LINK
- [ ] If the test requires an admin's personal access token, ensure that the test passes on your local environment with and without the `GITLAB_QA_ADMIN_ACCESS_TOKEN` provided.

<!-- Base labels. -->
/label ~"Quality" ~"QA" ~test

<!-- If the test is addressing a test gap, select a label according to the feature under test, please use just one. -->

/label ~"Quality:test-gap" ~"Quality:EE test gaps"

<!-- Select the appropriate feature label, ~"feature::addition" for tests added for new features, ~"type::maintenance" for tests added for existing features -->
/label ~"feature::addition" ~"type::maintenance"
