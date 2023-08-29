---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Grant users Kubernetes access **(FREE ALL BETA)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/390769) in GitLab 16.1, with [flags](../../../administration/feature_flags.md) named `environment_settings_to_graphql`, `kas_user_access`, `kas_user_access_project`, and `expose_authorized_cluster_agents`. This feature is in [Beta](../../../policy/experiment-beta-support.md#beta).
> - Feature flag `environment_settings_to_graphql` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124177) in GitLab 16.2.
> - Feature flags `kas_user_access`, `kas_user_access_project`, and `expose_authorized_cluster_agents` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125835) in GitLab 16.2.

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

  - `projects`: A list of projects whose members should have access.
  - `groups`: A list of groups whose members should have access.
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

## Configure access with user impersonation **(PREMIUM ALL)**

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
  - `agent.gitlab.com/access_type`: One of `personal_access_token`,
    `oidc_id_token`, or `session_cookie`.

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
