---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Install GitLab Runner with a cluster management project **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/merge_requests/5) in GitLab 14.0.

Assuming you already have a project created from a
[management project template](../../../../../user/clusters/management_project_template.md), to install GitLab Runner you should
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
- `runnerRegistrationToken`: The registration token for adding new runners to GitLab.
  This must be [retrieved from your GitLab instance](../../../../../ci/runners/index.md).

These values can be specified using [CI/CD variables](../../../../../ci/variables/index.md):

- `CI_SERVER_URL` is used for `gitlabUrl`. If you are using GitLab.com, you don't need to set this variable.
- `GITLAB_RUNNER_REGISTRATION_TOKEN` is used for `runnerRegistrationToken`

The methods of specifying these values are mutually exclusive. Either specify variables `GITLAB_RUNNER_REGISTRATION_TOKEN` and `CI_SERVER_URL` as CI variables (recommended) or provide values for `runnerRegistrationToken:` and `gitlabUrl:` in `applications/gitlab-runner/values.yaml.gotmpl`.

The runner registration token allows connection to a project by a runner and therefore should be treated as a secret to prevent malicious use and code exfiltration through a runner. For this reason, we recommend that you specify the runner registration token as a [protected variable](../../../../../ci/variables/index.md#protect-a-cicd-variable) and [masked variable](../../../../../ci/variables/index.md#mask-a-cicd-variable) and do not commit them to the Git repository in the `values.yaml.gotmpl` file.

You can customize the installation of GitLab Runner by defining
`applications/gitlab-runner/values.yaml.gotmpl` file in your cluster
management project. Refer to the
[chart](https://gitlab.com/gitlab-org/charts/gitlab-runner) for the
available configuration options.
