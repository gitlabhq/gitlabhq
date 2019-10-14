# Cluster management project (alpha)

CAUTION: **Warning:**
This is an _alpha_ feature, and it is subject to change at any time without
prior notice.

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/17866) in GitLab 12.4

A project can be designated as the management project for a cluster.
A management project can be used to run deployment jobs with
Kubernetes
[`cluster-admin`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles)
privileges.

This can be useful for:

- Creating pipelines to install cluster-wide applications into your cluster.
- Any jobs that require `cluster-admin` privileges.

## Permissions

Only the management project will receive `cluster-admin` privileges. All
other projects will continue to receive [namespace scoped `edit` level privileges](../project/clusters/index.md#rbac-cluster-resources).

## Usage

### Selecting a cluster management project

This will be implemented as part of [this
issue](https://gitlab.com/gitlab-org/gitlab/issues/32810).

### Configuring your pipeline

After designating a project as the management project for the cluster,
write a [`.gitlab-ci,yml`](../../ci/yaml/README.md) in that project. For example:

```yaml
configure cluster:
  stage: deploy
  script: kubectl get namespaces
  environment:
    name: production
```

### Setting the environment scope **(PREMIUM)**

[Environment
scopes](../project/clusters/index.md#setting-the-environment-scope-premium)
are usable when associating multiple clusters to the same management
project.

Each scope can only be used by a single cluster for a management project.

For example, let's say the following Kubernetes clusters are associated
to a management project:

| Cluster     | Environment scope |
| ----------- | ----------------- |
| Development | `*`               |
| Staging     | `staging`         |
| Production  | `production`      |

The the following environments set in
[`.gitlab-ci.yml`](../../ci/yaml/README.md) will deploy to the
Development, Staging, and Production cluster respectively.

```yaml
stages:
- deploy

configure development cluster:
  stage: deploy
  script: kubectl get namespaces
  environment:
    name: development

configure staging cluster:
  stage: deploy
  script: kubectl get namespaces
  environment:
    name: staging

configure production cluster:
  stage: deploy
  script: kubectl get namespaces
  environment:
    name: production
```

## Disabling this feature

This feature is enabled by default. To disable this feature, disable the
feature flag `:cluster_management_project`.

To check if the feature flag is enabled on your GitLab instance,
please ask an administrator to execute the following in a Rails console:

```ruby
Feature.enabled?(:cluster_management_project)     # Check if it's enabled or not.
Feature.disable(:cluster_management_project)      # Disable the feature flag.
```
