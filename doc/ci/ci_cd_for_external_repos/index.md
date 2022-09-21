---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: index, howto
---

# GitLab CI/CD for external repositories **(PREMIUM)**

>[Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/4642) in GitLab 10.6.

GitLab CI/CD can be used with [GitHub](github_integration.md), [Bitbucket Cloud](bitbucket_integration.md),
or any other Git server, though there are some [limitations](#limitations).

Instead of moving your entire project to GitLab, you can connect your
external repository to get the benefits of GitLab CI/CD.

Connecting an external repository sets up [repository mirroring](../../user/project/repository/mirror/index.md)
and creates a lightweight project with issues, merge requests, wiki, and
snippets disabled. These features
[can be re-enabled later](../../user/project/settings/index.md#configure-project-visibility-features-and-permissions).

## Connect to an external repository

To connect to an external repository:

1. In GitLab, on the top bar, select **Main menu > Projects > View all projects**.
1. On the right of the page, select **New project**.
1. Select **Run CI/CD for external repository**.
1. Select **GitHub** or **Repository by URL**.
1. Complete the fields.

## Pipelines for external pull requests

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/65139) in GitLab 12.3.

When using GitLab CI/CD with an [external repository on GitHub](github_integration.md),
it's possible to run a pipeline in the context of a Pull Request.

When you push changes to a remote branch in GitHub, GitLab CI/CD can run a pipeline for
the branch. However, when you open or update a Pull Request for that branch you may want to:

- Run extra jobs.
- Not run specific jobs.

For example:

```yaml
always-run:
  script: echo 'this should always run'

on-pull-requests:
  script: echo 'this should run on pull requests'
  only:
    - external_pull_requests

except-pull-requests:
  script: echo 'this should not run on pull requests'
  except:
    - external_pull_requests
```

### How it works

When a repository is imported from GitHub, GitLab subscribes to webhooks
for `push` and `pull_request` events. Once a `pull_request` event is received,
the Pull Request data is stored and kept as a reference. If the Pull Request
has just been created, GitLab immediately creates a pipeline for the external
pull request.

If changes are pushed to the branch referenced by the Pull Request and the
Pull Request is still open, a pipeline for the external pull request is
created.

GitLab CI/CD creates 2 pipelines in this case. One for the
branch push and one for the external pull request.

After the Pull Request is closed, no pipelines are created for the external pull
request, even if new changes are pushed to the same branch.

### Additional predefined variables

By using pipelines for external pull requests, GitLab exposes additional
[predefined variables](../variables/predefined_variables.md) to the pipeline jobs.

The variable names are prefixed with `CI_EXTERNAL_PULL_REQUEST_`.

### Limitations

This feature does not support:

- The [manual connection method](github_integration.md#connect-manually) required for GitHub Enterprise.
  If the integration is connected manually, external pull requests [do not trigger pipelines](https://gitlab.com/gitlab-org/gitlab/-/issues/323336#note_884820753).
- Pull requests from fork repositories. [Pull Requests from fork repositories are ignored](https://gitlab.com/gitlab-org/gitlab/-/issues/5667).

Given that GitLab creates 2 pipelines, if changes are pushed to a remote branch that
references an open Pull Request, both contribute to the status of the Pull Request
via GitHub integration. If you want to exclusively run pipelines on external pull
requests and not on branches you can add `except: [branches]` to the job specs.
[Read more](https://gitlab.com/gitlab-org/gitlab/-/issues/24089#workaround).
