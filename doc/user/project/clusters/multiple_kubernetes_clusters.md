---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Multiple Kubernetes clusters for a single project

> - Introduced in [GitLab Premium](https://about.gitlab.com/pricing/) 10.3
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/35094) to GitLab Free in 13.2.

You can associate more than one Kubernetes cluster to your
project. That way you can have different clusters for different environments,
like development, staging, production, and so on.
Add another cluster, like you did the first time, and make sure to
[set an environment scope](#setting-the-environment-scope) that
differentiates the new cluster from the rest.

## Setting the environment scope

When adding more than one Kubernetes cluster to your project, you need to differentiate
them with an environment scope. The environment scope associates clusters with [environments](../../../ci/environments/index.md) similar to how the
[environment-specific CI/CD variables](../../../ci/variables/index.md#limit-the-environment-scope-of-a-cicd-variable) work.

The default environment scope is `*`, which means all jobs, regardless of their
environment, use that cluster. Each scope can be used only by a single cluster
in a project, and a validation error occurs if otherwise. Also, jobs that don't
have an environment keyword set can't access any cluster.

For example, let's say the following Kubernetes clusters exist in a project:

| Cluster     | Environment scope |
| ----------- | ----------------- |
| Development | `*`               |
| Production  | `production`      |

And the following environments are set in
[`.gitlab-ci.yml`](../../../ci/yaml/index.md):

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
