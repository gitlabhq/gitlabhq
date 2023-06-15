---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference
---

# Dashboard for Kubernetes (Beta) **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/390769) in GitLab 16.1, with [flags](../../administration/feature_flags.md) named `environment_settings_to_graphql`, `kas_user_access`, `kas_user_access_project`, and `expose_authorized_cluster_agents`. This feature is in [Beta](../../policy/experiment-beta-support.md#beta).

Use the Dashboard for Kubernetes to understand the status of your clusters with an intuitive visual interface.
The dashboard works with every connected Kubernetes cluster, whether you deployed them
with CI/CD or GitOps.

For Flux users, the synchronization status of a given environment is not displayed in the dashboard.
[Issue 391581](https://gitlab.com/gitlab-org/gitlab/-/issues/391581) proposes to add this functionality.

## Configure a dashboard

Configure a dashboard to use it for a given environment.
You can configure dashboard for an environment that already exists, or
add one when you create an environment.

Prerequisite:

- The agent for Kubernetes must be shared with the environment's project, or its parent group, using the [`user_access`](../../user/clusters/agent/user_access.md) keyword.

### The environment already exists

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. Select **Operate > Environments**.
1. Select the environment to be associated with the Kubernetes.
1. Select **Edit**.
1. Select a GitLab agent for Kubernetes.
1. Select **Save**.

### The environment doesn't exist

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. Select **Operate > Environments**.
1. Select **New environment**.
1. Complete the **Name** field.
1. Select a GitLab agent for Kubernetes.
1. Select **Save**.

## View a dashboard

To view a configured dashboard:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. Select **Operate > Environments**.
1. Expand the environment associated with GitLab agent for Kubernetes.
1. Expand **Kubernetes overview**.

## Troubleshooting

When working with the Dashboard for Kubernetes, you might encounter the following issues.

### User cannot list resource in API group

You might get an error that states `Error: services is forbidden: User "gitlab:user:<user-name>" cannot list resource "<resource-name>" in API group "" at the cluster scope`.

This error happens when a user is not allowed to do the specified operation in the [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/).

To resolve, check your [RBAC configuration](../../user/clusters/agent/user_access.md#configure-kubernetes-access). If the RBAC is properly configured, contact your Kubernetes administrator.
