---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Install GitLab Runner with a cluster management project
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Assuming you already have a project created from a
[management project template](../../../../clusters/management_project_template.md), to install GitLab Runner you should
uncomment this line from your `helmfile.yaml`:

```yaml
  - path: applications/gitlab-runner/helmfile.yaml
```

GitLab Runner is installed by default into the `gitlab-managed-apps` namespace of your cluster.

## Required variables

For GitLab Runner to function, you _must_ specify the following in your
`applications/gitlab-runner/values.yaml.gotmpl` file:

- `gitlabUrl`: The GitLab server full URL (for example, `https://gitlab.example.com`)
  to register the Runner against.
- Runner token: This must be [retrieved](../../../../../ci/runners/_index.md) from your GitLab instance. You can use
  either of the following tokens:

  - `runnerToken`: The runner authentication token for the runner configuration [created in the GitLab UI](../../../../../ci/runners/runners_scope.md).
  - `runnerRegistrationToken` ([deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/102681) in GitLab 15.6 and scheduled to be removed in GitLab 17.0): The registration token for used to add new runners to GitLab.

These values can be specified using [CI/CD variables](../../../../../ci/variables/_index.md):

- `CI_SERVER_URL` is used for `gitlabUrl`. If you are using GitLab.com, you don't need to set this variable.
- `GITLAB_RUNNER_TOKEN` is used for `runnerToken`.
- `GITLAB_RUNNER_REGISTRATION_TOKEN` is used for `runnerRegistrationToken` (deprecated).

The methods of specifying these values are mutually exclusive. You can either:

- Specify the variables `GITLAB_RUNNER_TOKEN` and `CI_SERVER_URL` as CI variables (recommended).
- Provide values for `runnerToken:` and `gitlabUrl:` in `applications/gitlab-runner/values.yaml.gotmpl`.

The runner registration token allows connection to a project by a runner and therefore should be treated as a secret to prevent malicious use and code exfiltration through a runner. For this reason, we recommend that you specify the runner registration token as a [protected variable](../../../../../ci/variables/_index.md#protect-a-cicd-variable) and [masked variable](../../../../../ci/variables/_index.md#mask-a-cicd-variable) and do not commit them to the Git repository in the `values.yaml.gotmpl` file.

You can customize the installation of GitLab Runner by defining
`applications/gitlab-runner/values.yaml.gotmpl` file in your cluster
management project. Refer to the
[chart](https://gitlab.com/gitlab-org/charts/gitlab-runner) for the
available configuration options.
