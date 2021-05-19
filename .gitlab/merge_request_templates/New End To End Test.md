## Description of the test

<!--
Please link to the respective test case in the testcases project
-->

### Check-list

- [ ] Confirm the test has a [`testcase:` tag linking to an existing test case](https://docs.gitlab.com/ee/development/testing_guide/end_to_end/best_practices.html#link-a-test-to-its-test-case-issue) in the test case project.
- [ ] Note if the test is intended to run in specific scenarios. If a scenario is new, add a link to the MR that adds the new scenario.
- [ ] Follow the end-to-end tests [style guide](https://docs.gitlab.com/ee/development/testing_guide/end_to_end/style_guide.html) and [best practices](https://docs.gitlab.com/ee/development/testing_guide/end_to_end/best_practices.html).
- [ ] Use the appropriate [RSpec metadata tag(s)](https://docs.gitlab.com/ee/development/testing_guide/end_to_end/rspec_metadata_tests.html#rspec-metadata-for-end-to-end-tests).
- [ ] Ensure that a created resource is removed after test execution. A `Group` resource can be shared between multiple tests. Do not remove it unless it has a unique path. Note that we have a cleanup job that periodically removes groups under `gitlab-qa-sandbox-group`.
- [ ] Ensure that no [transient bugs](https://about.gitlab.com/handbook/engineering/quality/issue-triage/#transient-bugs) are hidden accidentally due to the usage of `waits` and `reloads`.
- [ ] Verify the tags to ensure it runs on the desired test environments.
- [ ] If this MR has a dependency on another MR, such as a GitLab QA MR, specify the order in which the MRs should be merged.
- [ ] (If applicable) Create a follow-up issue to document [the special setup](https://docs.gitlab.com/ee/development/testing_guide/end_to_end/running_tests_that_require_special_setup.html) necessary to run the test: ISSUE_LINK
- [ ] If the test requires an admin's personal access token, ensure that the test passes on your local with and without the `GITLAB_QA_ADMIN_ACCESS_TOKEN` provided.

<!-- Base labels. -->
/label ~"Quality" ~"QA" ~test

<!-- If the test is addressing a test gap, select a label according to the feature under test, please use just one. -->

/label ~"Quality:test-gap" ~"Quality:EE test gaps"

<!-- Select the appropriate feature label, ~"feature::addition" for tests added for new features, ~"feature::maintenance" for tests added for existing features -->
/label ~"feature::addition" ~"feature::maintenance" 
