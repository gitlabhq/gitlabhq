---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Grant users Kubernetes access
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated
**Status:** Beta

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/390769) in GitLab 16.1, with [flags](../../../administration/feature_flags.md) named `environment_settings_to_graphql`, `kas_user_access`, `kas_user_access_project`, and `expose_authorized_cluster_agents`. This feature is in [beta](../../../policy/development_stages_support.md#beta).
> - Feature flag `environment_settings_to_graphql` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124177) in GitLab 16.2.
> - Feature flags `kas_user_access`, `kas_user_access_project`, and `expose_authorized_cluster_agents` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125835) in GitLab 16.2.
> - The [limit of agent connection sharing was raised](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149844) from 100 to 500 in GitLab 17.0

As an administrator of Kubernetes clusters in an organization, you can grant Kubernetes access to members
of a specific project or group.

Granting access also activates the Dashboard for Kubernetes for a project or group.

For self-managed instances, make sure you either:

- Host your GitLab instance and [KAS](../../../administration/clusters/kas.md) on the same domain.
- Host KAS on a subdomain of GitLab. For example, GitLab on `gitlab.com` and KAS on `kas.gitlab.com`.

## Configure Kubernetes access

Configure access when you want to grant users access
to a Kubernetes cluster.

Prerequisites:

- The agent for Kubernetes is installed in the Kubernetes cluster.
- You must have the Developer role or higher.

To configure access:

- In the agent configuration file, define a `user_access` keyword with the following parameters:

  - `projects`: A list of projects whose members should have access. You can authorize up to 500 projects.
  - `groups`: A list of groups whose members should have access. You can authorize up to 500 groups. It grants access to the group and all its descendants.
  - `access_as`: Required. For plain access, the value is `{ agent: {...} }`.

After you configure access, requests are forwarded to the API server using
the agent service account.
For example:

```yaml
# .gitlab/agents/my-agent/config.yaml

user_access:
  access_as:
    agent: {}
  projects:
    - id: group-1/project-1
    - id: group-2/project-2
  groups:
    - id: group-2
    - id: group-3/subgroup
```

## Configure access with user impersonation

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can grant access to a Kubernetes cluster and transform
requests into impersonation requests for authenticated users.

Prerequisites:

- The agent for Kubernetes is installed in the Kubernetes cluster.
- You must have the Developer role or higher.

To configure access with user impersonation:

- In the agent configuration file, define a `user_access` keyword with the following parameters:

  - `projects`: A list of projects whose members should have access.
  - `groups`: A list of groups whose members should have access.
  - `access_as`: Required. For user impersonation, the value is `{ user: {...} }`.

After you configure access, requests are transformed into impersonation requests for
authenticated users.

### User impersonation workflow

The installed `agentk` impersonates the given users as follows:

- `UserName` is `gitlab:user:<username>`
- `Groups` is:
  - `gitlab:user`: Common to all requests coming from GitLab users.
  - `gitlab:project_role:<project_id>:<role>` for each role in each authorized project.
  - `gitlab:group_role:<group_id>:<role>` for each role in each authorized group.
- `Extra` carries additional information about the request:
  - `agent.gitlab.com/id`: The agent ID.
  - `agent.gitlab.com/username`: The username of the GitLab user.
  - `agent.gitlab.com/config_project_id`: The agent configuration project ID.
  - `agent.gitlab.com/access_type`: One of `personal_access_token` or `session_cookie`. Ultimate only.

Only projects and groups directly listed in the under `user_access` in the configuration
file are impersonated. For example:

```yaml
# .gitlab/agents/my-agent/config.yaml

user_access:
  access_as:
    user: {}
  projects:
    - id: group-1/project-1 # group_id=1, project_id=1
    - id: group-2/project-2 # group_id=2, project_id=2
  groups:
    - id: group-2 # group_id=2
    - id: group-3/subgroup # group_id=3, group_id=4
```

In this configuration:

- If a user is a member of only `group-1`, they receive
  only the Kubernetes RBAC groups `gitlab:project_role:1:<role>`.
- If a user is a member of `group-2`, they receive both Kubernetes RBAC groups:
  - `gitlab:project_role:2:<role>`,
  - `gitlab:group_role:2:<role>`.

### RBAC authorization

Impersonated requests require `ClusterRoleBinding` or `RoleBinding` to identify the resource permissions
inside Kubernetes. See [RBAC authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
for the appropriate configuration.

For example, if you allow maintainers in `awesome-org/deployment` project (ID: 123) to read the Kubernetes workloads,
you must add a `ClusterRoleBinding` resource to your Kubernetes configuration:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: my-cluster-role-binding
roleRef:
  name: view
  kind: ClusterRole
  apiGroup: rbac.authorization.k8s.io
subjects:
  - name: gitlab:project_role:123:maintainer
    kind: Group
```

## Access a cluster with the Kubernetes API

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131144) in GitLab 16.4.

You can configure an agent to allow GitLab users to access a cluster with the Kubernetes API.

Prerequisites:

- You have an agent configured with the `user_access` entry.

### Configure local access with the GitLab CLI (recommended)

You can use the [GitLab CLI `glab`](../../../editor_extensions/gitlab_cli/_index.md) to create or update
a Kubernetes configuration file to access the agent Kubernetes API.

Use `glab cluster agent` commands to manage cluster connections:

1. View a list of all the agents associated with your project:

```shell
glab cluster agent list --repo '<group>/<project>'

# If your current working directory is the Git repository of the project with the agent, you can omit the --repo option:
glab cluster agent list
```

1. Use the numerical agent ID presented in the first column of the output to update your `kubeconfig`:

```shell
glab cluster agent update-kubeconfig --repo '<group>/<project>' --agent '<agent-id>' --use-context
```

1. Verify the update with `kubectl` or your preferred Kubernetes tooling:

```shell
kubectl get nodes
```

The `update-kubeconfig` command sets `glab cluster agent get-token` as a
[credential plugin](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#client-go-credential-plugins)
for Kubernetes tools to retrieve a token. The `get-token` command creates and
returns a personal access token that is valid until the end of the current day.
Kubernetes tools cache the token until it expires, the API returns an authorization error, or the process exits. Expect all subsequent calls to your Kubernetes tooling to create a new token.

The `glab cluster agent update-kubeconfig` command supports a number of command line flags. You can view all supported flags with `glab cluster agent update-kubeconfig --help`.

Some examples:

```shell
# When the current working directory is the Git repository where the agent is registered the --repo / -R flag can be omitted
glab cluster agent update-kubeconfig --agent '<agent-id>'

# When the --use-context option is specified the `current-context` of the kubeconfig file is changed to the agent context
glab cluster agent update-kubeconfig --agent '<agent-id>' --use-context

# The --kubeconfig flag can be used to specify an alternative kubeconfig path
glab cluster agent update-kubeconfig --agent '<agent-id>' --kubeconfig ~/gitlab.kubeconfig
```

### Configure local access manually using a personal access token

You can configure access to a Kubernetes cluster using a long-lived personal access token:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Operate > Kubernetes clusters** and retrieve the numerical ID of the agent you want to access. You need the ID to construct the full API token.
1. Create a [personal access token](../../profile/personal_access_tokens.md) with the `k8s_proxy` scope. You need the access token to construct the full API token.
1. Construct `kubeconfig` entries to access the cluster:
   1. Make sure that the proper `kubeconfig` is selected.
      For example, you can set the `KUBECONFIG` environment variable.
   1. Add the GitLab KAS proxy cluster to the `kubeconfig`:

      ```shell
      kubectl config set-cluster <cluster_name> --server "https://kas.gitlab.com/k8s-proxy"
      ```

      The `server` argument points to the KAS address of your GitLab instance.
      On GitLab.com, this is `https://kas.gitlab.com/k8s-proxy`.
      You can get the KAS address of your instance when you register an agent.

   1. Use your numerical agent ID and personal access token to construct an API token:

      ```shell
      kubectl config set-credentials <gitlab_user> --token "pat:<agent-id>:<token>"
      ```

   1. Add the context to combine the cluster and the user:

      ```shell
      kubectl config set-context <gitlab_agent> --cluster <cluster_name> --user <gitlab_user>
      ```

   1. Activate the new context:

      ```shell
      kubectl config use-context <gitlab_agent>
      ```

1. Check that the configuration works:

   ```shell
   kubectl get nodes
   ```

The configured user can access your cluster with the Kubernetes API.

## Related topics

- [Architectural blueprint](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kubernetes_user_access.md)
- [Dashboard for Kubernetes](https://gitlab.com/groups/gitlab-org/-/epics/2493)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
