## What does this MR do?

<!--
Please describe why the end-to-end test is being quarantined/ de-quarantined.

Please note that the aim of quarantining a test is not to get back a green pipeline, but rather to reduce
the noise (due to constantly failing tests, flaky tests, and so on) so that new failures are not missed.
-->


### E2E Test Failure issue(s)

<!-- Please link to the respective E2E test failure issue. -->


### Check-list

- [ ] General code guidelines check-list
  - [ ] [Code review guidelines](https://docs.gitlab.com/ee/development/code_review.html)
  - [ ] [Style guides](https://docs.gitlab.com/ee/development/contributing/style_guides.html)
- [ ] Quarantine test check-list
  - [ ] Follow the [Quarantining Tests guide](https://about.gitlab.com/handbook/engineering/quality/guidelines/debugging-qa-test-failures/#quarantining-tests).
  - [ ] Confirm the test has a [`quarantine:` tag with the specified quarantine type](https://about.gitlab.com/handbook/engineering/quality/guidelines/debugging-qa-test-failures/#quarantined-test-types).
  - [ ] Note if the test should be [quarantined for a specific environment](https://docs.gitlab.com/ee/development/testing_guide/end_to_end/execution_context_selection.html#quarantine-a-test-for-a-specific-environment).
- [ ] Dequarantine test check-list
  - [ ] Follow the [Dequarantining Tests guide](https://about.gitlab.com/handbook/engineering/quality/guidelines/debugging-qa-test-failures/#dequarantining-tests).
  - [ ] Confirm the test consistently passes on the target GitLab environment(s).
    - [ ] (Optionally) [Trigger a manual GitLab-QA pipeline](https://about.gitlab.com/handbook/engineering/quality/guidelines/tips-and-tricks/#running-gitlab-qa-pipeline-against-a-specific-gitlab-release) against a specific GitLab environment using the `RELEASE` variable from the `package-and-qa` job of the current merge request.
- [ ] To ensure a faster turnaround, ask in the `#quality` Slack channel for someone to review and merge the merge request, rather than assigning it directly.

<!-- Base labels. -->
/label ~"Quality" ~"QA" ~"feature" ~"feature::maintenance"

<!-- Labels to pick into auto-deploy. -->
/label ~"Pick into auto-deploy" ~"priority::1" ~"severity::1"

<!--
Choose the stage that appears in the test path, e.g. ~"devops::create" for
`qa/specs/features/browser_ui/3_create/web_ide/add_file_template_spec.rb`.
-->
/label ~devops::

<!-- Select the current milestone. -->
/milestone %
