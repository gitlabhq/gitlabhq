---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Cluster management project (deprecated)
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Disabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/353410) in GitLab 15.0.

WARNING:
The cluster management project was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.
To manage cluster applications, use the [GitLab agent](agent/_index.md)
with the [Cluster Management Project Template](management_project_template.md).

FLAG:
On GitLab Self-Managed, by default this feature is not available. To make it available, an administrator can [enable the feature flag](../../administration/feature_flags.md) named `certificate_based_clusters`.

A project can be designated as the management project for a cluster.
A management project can be used to run deployment jobs with
Kubernetes
[`cluster-admin`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles)
privileges.

This can be useful for:

- Creating pipelines to install cluster-wide applications into your cluster, see [management project template](management_project_template.md) for details.
- Any jobs that require `cluster-admin` privileges.

## Permissions

Only the management project receives `cluster-admin` privileges. All
other projects continue to receive [namespace scoped `edit` level privileges](../project/clusters/cluster_access.md#rbac-cluster-resources).

Management projects are restricted to the following:

- For project-level clusters, the management project must be in the same
  namespace (or descendants) as the cluster's project.
- For group-level clusters, the management project must be in the same
  group (or descendants) as the cluster's group.
- For instance-level clusters, there are no such restrictions.

## How to create and configure a cluster management project

To use a cluster management project to manage your cluster:

1. Create a new project to serve as the cluster management project
   for your cluster.
1. [Associate the cluster with the management project](#associate-the-cluster-management-project-with-the-cluster).
1. [Configure your cluster's pipelines](#configuring-your-pipeline).
1. [Set the environment scope](#setting-the-environment-scope).

### Associate the cluster management project with the cluster

To associate a cluster management project with your cluster:

1. Go to the appropriate configuration page. For a:
   - [Project-level cluster](../project/clusters/_index.md), go to your project's
     **Operate > Kubernetes clusters** page.
   - [Group-level cluster](../group/clusters/_index.md), go to your group's **Kubernetes**
     page.
   - [Instance-level cluster](../instance/clusters/_index.md):
     1. On the left sidebar, at the bottom, select **Admin**.
     1. Select **Kubernetes**.
1. Expand **Advanced settings**.
1. From the **Cluster management project** dropdown list, select the cluster management project
   you created in the previous step.

### Configuring your pipeline

After designating a project as the management project for the cluster,
add a `.gitlab-ci.yml` file in that project. For example:

```yaml
configure cluster:
  stage: deploy
  script: kubectl get namespaces
  environment:
    name: production
```

### Setting the environment scope

[Environment scopes](../project/clusters/multiple_kubernetes_clusters.md#setting-the-environment-scope)
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

The environments set in the `.gitlab-ci.yml` file deploy to the
Development, Staging, and Production cluster.

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
