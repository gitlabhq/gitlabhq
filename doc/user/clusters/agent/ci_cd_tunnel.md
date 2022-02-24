---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Using a GitLab CI/CD workflow for Kubernetes **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/327409) in GitLab 14.1.
> - The pre-configured `KUBECONFIG` was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/324275) in GitLab 14.2.
> - The ability to authorize groups was [introduced](https://gitlab.com/groups/gitlab-org/-/epics/5784) in GitLab 14.3.
> - [Moved](https://gitlab.com/groups/gitlab-org/-/epics/6290) to GitLab Free in 14.5.
> - Support for Omnibus installations was [introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5686) in GitLab 14.5.

You can use GitLab CI/CD to safely deploy to and update your Kubernetes clusters.

To do so, you install a GitLab agent in your cluster. Then in your GitLab CI/CD pipelines,
you can refer to the cluster connection as a Kubernetes context.
Then you can run Kubernetes API commands as part of your GitLab CI/CD pipeline.

To ensure access to your cluster is safe:

- Each agent has a separate context (`kubecontext`).
- Only the project where the agent is, and any additional projects you authorize can access the agent in your cluster.

You do not need to have a runner in the cluster with the agent.

## GitLab CI/CD workflow steps

To update a Kubernetes cluster by using GitLab CI/CD, complete the following steps.

1. Ensure you have a working Kubernetes cluster and the manifests are in a GitLab project.
1. In the same GitLab project, [register and install the GitLab agent](install/index.md).
1. [Update your `.gitlab-ci.yml` file](#update-your-gitlab-ciyml-file-to-run-kubectl-commands) to
   select the agent's Kubernetes context and run the Kubernetes API commands.
1. Run your pipeline to deploy to or update the cluster.

If you have multiple GitLab projects that contain Kubernetes manifests:

1. [Install the GitLab agent](install/index.md) in its own project, or in one of the
   GitLab projects where you keep Kubernetes manifests.
1. [Authorize the agent](#authorize-the-agent) to access your GitLab projects.
1. Optional. For added security, [use impersonation](#use-impersonation-to-restrict-project-and-group-access).
1. [Update your `.gitlab-ci.yml` file](#update-your-gitlab-ciyml-file-to-run-kubectl-commands) to
   select the agent's Kubernetes context and run the Kubernetes API commands.
1. Run your pipeline to deploy to or update the cluster.

## Authorize the agent

You must authorize the agent to access the project where you keep your Kubernetes manifests.
You can authorize the agent to access individual projects, or authorize a group or subgroup,
so all projects within have access. For added security, you can also
[use impersonation](#use-impersonation-to-restrict-project-and-group-access).

### Authorize the agent to access your projects

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/327850) in GitLab 14.4.

To authorize the agent to access the GitLab project where you keep Kubernetes manifests:

1. On the top bar, select **Menu > Projects** and find the project that contains the agent configuration file (`config.yaml`).
1. Edit the file. Under the `ci_access` keyword, add the `projects` attribute.
1. For the `id`, add the path:

   ```yaml
   ci_access:
     projects:
     - id: path/to/project
   ```

   - The Kubernetes projects must be in the same group hierarchy as the project where the agent's configuration is.
   - You can authorize up to 100 projects.

All CI/CD jobs now include a `KUBECONFIG` with contexts for every shared agent connection.
Choose the context to run `kubectl` commands from your CI/CD scripts.

### Authorize the agent to access projects in your groups

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5784) in GitLab 14.3.

To authorize the agent to access all of the GitLab projects in a group or subgroup:

1. On the top bar, select **Menu > Projects** and find the project that contains the agent configuration file (`config.yaml`).
1. Edit the file. Under the `ci_access` keyword, add the `groups` attribute.
1. For the `id`, add the path:

   ```yaml
   ci_access:
     groups:
     - id: path/to/group/subgroup
   ```

   - The Kubernetes projects must be in the same group hierarchy as the project where the agent's configuration is.
   - You can authorize up to 100 groups.

All the projects that belong to the group are now authorized to access the agent.
All CI/CD jobs now include a `KUBECONFIG` with contexts for every shared agent connection.
Choose the context to run `kubectl` commands from your CI/CD scripts.

## Update your `.gitlab-ci.yml` file to run `kubectl` commands

In the project where you want to run Kubernetes commands, edit your project's `.gitlab-ci.yml` file.

In the first command under the `script` keyword, set your agent's context.
Use the format `path/to/agent/repository:agent-name`. For example:

```yaml
 deploy:
   image:
     name: bitnami/kubectl:latest
     entrypoint: [""]
   script:
   - kubectl config get-contexts
   - kubectl config use-context path/to/agent/repository:agent-name
   - kubectl get pods
```

If you are not sure what your agent's context is, open a terminal and connect to your cluster.
Run `kubectl config get-contexts`.

## Use impersonation to restrict project and group access **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/345014) in GitLab 14.5.

By default, your CI/CD job inherits all the permissions from the service account used to install the
agent in the cluster.
To restrict access to your cluster, you can use [impersonation](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#user-impersonation).

To specify impersonations, use the `access_as` attribute in your agent configuration file and use Kubernetes RBAC rules to manage impersonated account permissions.

You can impersonate:

- The agent itself (default).
- The CI/CD job that accesses the cluster.
- A specific user or system account defined within the cluster.

### Impersonate the agent

The agent is impersonated by default. You don't need to do anything to impersonate it.

### Impersonate the CI/CD job that accesses the cluster

To impersonate the CI/CD job that accesses the cluster, under the `access_as` key, add the `ci_job: {}` key-value.

When the agent makes the request to the actual Kubernetes API, it sets the
impersonation credentials in the following way:

- `UserName` is set to `gitlab:ci_job:<job id>`. Example: `gitlab:ci_job:1074499489`.
- `Groups` is set to:
  - `gitlab:ci_job` to identify all requests coming from CI jobs.
  - The list of IDs of groups the project is in.
  - The project ID.
  - The slug of the environment this job belongs to.

    Example: for a CI job in `group1/group1-1/project1` where:

    - Group `group1` has ID 23.
    - Group `group1/group1-1` has ID 25.
    - Project `group1/group1-1/project1` has ID 150.
    - Job running in a prod environment.

   Group list would be `[gitlab:ci_job, gitlab:group:23, gitlab:group:25, gitlab:project:150, gitlab:project_env:150:prod]`.

- `Extra` carries extra information about the request. The following properties are set on the impersonated identity:

| Property | Description |
| -------- | ----------- |
| `agent.gitlab.com/id` | Contains the agent ID. |
| `agent.gitlab.com/config_project_id` | Contains the agent's configuration project ID. |
| `agent.gitlab.com/project_id` | Contains the CI project ID. |
| `agent.gitlab.com/ci_pipeline_id` | Contains the CI pipeline ID. |
| `agent.gitlab.com/ci_job_id` | Contains the CI job ID. |
| `agent.gitlab.com/username` | Contains the username of the user the CI job is running as. |
| `agent.gitlab.com/environment_slug` | Contains the slug of the environment. Only set if running in an environment. |

Example to restrict access by the CI/CD job's identity:

```yaml
ci_access:
  projects:
  - id: path/to/project
    access_as:
      ci_job: {}
```

### Impersonate a static identity

For a given connection, you can use a static identity for the impersonation.

Under the `access_as` key, add the `impersonate` key to make the request using the provided identity.

The identity can be specified with the following keys:

- `username` (required)
- `uid`
- `groups`
- `extra`

See the [official Kubernetes documentation for details](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#user-impersonation).

## Troubleshooting

### `kubectl` commands not supported

The commands `kubectl exec`, `kubectl cp`, and `kubectl attach` are not supported.
Anything that uses these API endpoints does not work, because they use the deprecated
SPDY protocol.
[An issue exists](https://gitlab.com/gitlab-org/gitlab/-/issues/346248) to add support for these commands.

### Grant write permissions to `~/.kube/cache`

Tools like `kubectl`, Helm, `kpt`, and `kustomize` cache information about
the cluster in `~/.kube/cache`. If this directory is not writable, the tool fetches information on each invocation,
making interactions slower and creating unnecessary load on the cluster. For the best experience, in the
image you use in your .`gitlab-ci.yml` file, ensure this directory is writable.

### Enable TLS

If you are on a self-managed GitLab instance, ensure your instance is configured with Transport Layer Security (TLS).

If you attempt to use `kubectl` without TLS, you might get an error like:

```shell
$ kubectl get pods
error: You must be logged in to the server (the server has asked for the client to provide credentials)
```
