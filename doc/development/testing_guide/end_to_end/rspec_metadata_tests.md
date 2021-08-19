---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# RSpec metadata for end-to-end tests

This is a partial list of the [RSpec metadata](https://relishapp.com/rspec/rspec-core/docs/metadata/user-defined-metadata)
(a.k.a. tags) that are used in our end-to-end tests.

<!-- Please keep the tags in alphabetical order -->

| Tag | Description |
|-----|-------------|
| `:elasticsearch`  | The test requires an Elasticsearch service. It is used by the [instance-level scenario](https://gitlab.com/gitlab-org/gitlab-qa#definitions) [`Test::Integration::Elasticsearch`](https://gitlab.com/gitlab-org/gitlab/-/blob/72b62b51bdf513e2936301cb6c7c91ec27c35b4d/qa/qa/ee/scenario/test/integration/elasticsearch.rb) to include only tests that require Elasticsearch. |
| `:except`         | The test is to be run in their typical execution contexts _except_ as specified. See [test execution context selection](execution_context_selection.md) for more information. |
| `:geo`            | The test requires two GitLab Geo instances - a primary and a secondary - to be spun up. |
| `:gitaly_cluster` | The test runs against a GitLab instance where repositories are stored on redundant Gitaly nodes behind a Praefect node. All nodes are [separate containers](../../../administration/gitaly/praefect.md#requirements). Tests that use this tag have a longer setup time since there are three additional containers that need to be started. |
| `:github`         | The test requires a GitHub personal access token. |
| `:group_saml`     | The test requires a GitLab instance that has SAML SSO enabled at the group level. Interacts with an external SAML identity provider. Paired with the `:orchestrated` tag. |
| `:instance_saml`  | The test requires a GitLab instance that has SAML SSO enabled at the instance level. Interacts with an external SAML identity provider. Paired with the `:orchestrated` tag. |
| `:jira`           | The test requires a Jira Server. [GitLab-QA](https://gitlab.com/gitlab-org/gitlab-qa) provisions the Jira Server in a Docker container when the `Test::Integration::Jira` test scenario is run.
| `:kubernetes`     | The test includes a GitLab instance that is configured to be run behind an SSH tunnel, allowing a TLS-accessible GitLab. This test also includes provisioning of at least one Kubernetes cluster to test against. _This tag is often be paired with `:orchestrated`._ |
| `:ldap_no_server` | The test requires a GitLab instance to be configured to use LDAP. To be used with the `:orchestrated` tag. It does not spin up an LDAP server at orchestration time. Instead, it creates the LDAP server at runtime. |
| `:ldap_no_tls`    | The test requires a GitLab instance to be configured to use an external LDAP server with TLS not enabled. |
| `:ldap_tls`       | The test requires a GitLab instance to be configured to use an external LDAP server with TLS enabled. |
| `:mattermost`     | The test requires a GitLab Mattermost service on the GitLab instance. |
| `:object_storage` | The test requires a GitLab instance to be configured to use multiple [object storage types](../../../administration/object_storage.md). Uses MinIO as the object storage server. |
| `:only`           | The test is only to be run in specific execution contexts. See [test execution context selection](execution_context_selection.md) for more information. |
| `:orchestrated`   | The GitLab instance under test may be [configured by `gitlab-qa`](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/what_tests_can_be_run.md#orchestrated-tests) to be different to the default GitLab configuration, or `gitlab-qa` may launch additional services in separate Docker containers, or both. Tests tagged with `:orchestrated` are excluded when testing environments where we can't dynamically modify the GitLab configuration (for example, Staging). |
| `:packages`       | The test requires a GitLab instance that has the [Package Registry](../../../administration/packages/#gitlab-package-registry-administration) enabled. |
| `:quarantine`     | The test has been [quarantined](https://about.gitlab.com/handbook/engineering/quality/guidelines/debugging-qa-test-failures/#quarantining-tests), runs in a separate job that only includes quarantined tests, and is allowed to fail. The test is skipped in its regular job so that if it fails it doesn't hold up the pipeline. Note that you can also [quarantine a test only when it runs in a specific context](execution_context_selection.md#quarantine-a-test-for-a-specific-environment). |
| `:relative_url`   | The test requires a GitLab instance to be installed under a [relative URL](../../../install/relative_url.md). |
| `:reliable`       | The test has been [promoted to a reliable test](https://about.gitlab.com/handbook/engineering/quality/guidelines/reliable-tests/#promoting-an-existing-test-to-reliable) meaning it passes consistently in all pipelines, including merge requests. |
| `:repository_storage` |  The test requires a GitLab instance to be configured to use multiple [repository storage paths](../../../administration/repository_storage_paths.md). Paired with the `:orchestrated` tag. |
| `:requires_admin` | The test requires an admin account. Tests with the tag are excluded when run against Canary and Production environments. |
| `:requires_git_protocol_v2`   | The test requires that Git protocol version 2 is enabled on the server. It's assumed to be enabled by default but if not the test can be skipped by setting `QA_CAN_TEST_GIT_PROTOCOL_V2` to `false`. |
| `:requires_praefect`   | The test requires that the GitLab instance uses [Gitaly Cluster](../../../administration/gitaly/praefect.md) (a.k.a. Praefect) as the repository storage . It's assumed to be used by default but if not the test can be skipped by setting `QA_CAN_TEST_PRAEFECT` to `false`. |
| `:runner`         | The test depends on and sets up a GitLab Runner instance, typically to run a pipeline. |
| `:skip_live_env`  | The test is excluded when run against live deployed environments such as Staging, Canary, and Production. |
| `:skip_signup_disabled` | The test uses UI to sign up a new user and is skipped in any environment that does not allow new user registration via the UI. |
| `:smoke`          | The test belongs to the test suite which verifies basic functionality of a GitLab instance.|
| `:smtp`           | The test requires a GitLab instance to be configured to use an SMTP server. Tests SMTP notification email delivery from GitLab by using MailHog. |
| `:testcase`       | The link to the test case issue in the [Quality Test Cases project](https://gitlab.com/gitlab-org/quality/testcases/). |
| `:transient`      | The test tests transient bugs. It is excluded by default. |
