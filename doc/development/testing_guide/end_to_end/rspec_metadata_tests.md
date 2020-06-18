# RSpec metadata for end-to-end tests

This is a partial list of the [RSpec metadata](https://relishapp.com/rspec/rspec-core/docs/metadata/user-defined-metadata)
(a.k.a. tags) that are used in our end-to-end tests.

<!-- Please keep the tags in alphabetical order -->

| Tag | Description |
|-----|-------------|
| `:elasticsearch`  | The test requires an Elasticsearch service. It is used by the [instance-level scenario](https://gitlab.com/gitlab-org/gitlab-qa#definitions) [`Test::Integration::Elasticsearch`](https://gitlab.com/gitlab-org/gitlab/-/blob/72b62b51bdf513e2936301cb6c7c91ec27c35b4d/qa/qa/ee/scenario/test/integration/elasticsearch.rb) to include only tests that require Elasticsearch. |
| `:kubernetes`     | The test includes a GitLab instance that is configured to be run behind an SSH tunnel, allowing a TLS-accessible GitLab. This test will also include provisioning of at least one Kubernetes cluster to test against. *This tag is often be paired with `:orchestrated`.* |
| `:orchestrated`   | The GitLab instance under test may be [configured by `gitlab-qa`](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/what_tests_can_be_run.md#orchestrated-tests) to be different to the default GitLab configuration, or `gitlab-qa` may launch additional services in separate Docker containers, or both. Tests tagged with `:orchestrated` are excluded when testing environments where we can't dynamically modify GitLab's configuration (for example, Staging). |
| `:quarantine`     | The test has been [quarantined](https://about.gitlab.com/handbook/engineering/quality/guidelines/debugging-qa-test-failures/#quarantining-tests), will run in a separate job that only includes quarantined tests, and is allowed to fail. The test will be skipped in its regular job so that if it fails it will not hold up the pipeline. |
| `:reliable`       | The test has been [promoted to a reliable test](https://about.gitlab.com/handbook/engineering/quality/guidelines/reliable-tests/#promoting-an-existing-test-to-reliable) meaning it passes consistently in all pipelines, including merge requests. |
| `:requires_admin` | The test requires an admin account. Tests with the tag are excluded when run against Canary and Production environments. |
| `:runner`         | The test depends on and will set up a GitLab Runner instance, typically to run a pipeline. |
| `:gitaly_ha`      | The test will run against a GitLab instance where repositories are stored on redundant Gitaly nodes behind a Praefect node. All nodes are [separate containers](../../../administration/gitaly/praefect.md#requirements-for-configuring-a-gitaly-cluster). Tests that use this tag have a longer setup time since there are three additional containers that need to be started. |
| `:skip_live_env`  | The test will be excluded when run against live deployed environments such as Staging, Canary, and Production. |
| `:jira`           | The test requires a Jira Server. [GitLab-QA](https://gitlab.com/gitlab-org/gitlab-qa) will provision the Jira Server in a Docker container when the `Test::Integration::Jira` test scenario is run.
