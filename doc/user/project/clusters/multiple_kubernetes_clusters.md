---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Multiple clusters per project with cluster certificates (deprecated)
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed

WARNING:
Using multiple Kubernetes clusters for a single project **with cluster
certificates** was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.
To connect clusters to GitLab, use the [GitLab agent](../../clusters/agent/_index.md).

You can associate more than one Kubernetes cluster to your
project. That way you can have different clusters for different environments,
like development, staging, production, and so on.
Add another cluster, like you did the first time, and make sure to
[set an environment scope](#setting-the-environment-scope) that
differentiates the new cluster from the rest.

## Setting the environment scope

When adding more than one Kubernetes cluster to your project, you need to differentiate
them with an environment scope. The environment scope associates clusters with [environments](../../../ci/environments/_index.md) similar to how the
[environment-specific CI/CD variables](../../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable) work.

The default environment scope is `*`, which means all jobs, regardless of their
environment, use that cluster. Each scope can be used only by a single cluster
in a project, and a validation error occurs if otherwise. Also, jobs that don't
have an environment keyword set can't access any cluster.

For example, let's say the following Kubernetes clusters exist in a project:

| Cluster     | Environment scope |
| ----------- | ----------------- |
| Development | `*`               |
| Production  | `production`      |

And the following environments are set in the `.gitlab-ci.yml` file:

```yaml
stages:
  - test
  - deploy

test:
  stage: test
  script: sh test

deploy to staging:
  stage: deploy
  script: make deploy
  environment:
    name: staging
    url: https://staging.example.com/

deploy to production:
  stage: deploy
  script: make deploy
  environment:
    name: production
    url: https://example.com/
```

The results:

- The Development cluster details are available in the `deploy to staging`
  job.
- The production cluster details are available in the `deploy to production`
  job.
- No cluster details are available in the `test` job because it doesn't
  define any environment.
