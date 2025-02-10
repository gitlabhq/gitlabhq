---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Using GitLab CI/CD with a Kubernetes cluster
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Agent connection sharing limit [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149844) from 100 to 500 in GitLab 17.0.

You can use GitLab CI/CD to safely connect, deploy, and update your Kubernetes clusters.

To do so, [install an agent in your cluster](install/_index.md). When done, you have a Kubernetes context and can
run Kubernetes API commands in your GitLab CI/CD pipeline.

To ensure access to your cluster is safe:

- Each agent has a separate context (`kubecontext`).
- Only the project where the agent is configured, and any additional projects you authorize, can access the agent in your cluster.

To use GitLab CI/CD to interact with your cluster, runners must be registered with GitLab. However, these runners do not have to be in the cluster where the agent is.

Prerequisites:

- Make sure [GitLab CI/CD is enabled](../../../ci/pipelines/settings.md#disable-gitlab-cicd-pipelines).

## Use GitLab CI/CD with your cluster

To update a Kubernetes cluster with GitLab CI/CD:

1. Ensure you have a working Kubernetes cluster and the manifests are in a GitLab project.
1. In the same GitLab project, [register and install the GitLab agent](install/_index.md).
1. [Update your `.gitlab-ci.yml` file](#update-your-gitlab-ciyml-file-to-run-kubectl-commands) to
   select the agent's Kubernetes context and run the Kubernetes API commands.
1. Run your pipeline to deploy to or update the cluster.

If you have multiple GitLab projects that contain Kubernetes manifests:

1. [Install the GitLab agent](install/_index.md) in its own project, or in one of the
   GitLab projects where you keep Kubernetes manifests.
1. [Authorize the agent](#authorize-the-agent) to access your GitLab projects.
1. Optional. For added security, [use impersonation](#restrict-project-and-group-access-by-using-impersonation).
1. [Update your `.gitlab-ci.yml` file](#update-your-gitlab-ciyml-file-to-run-kubectl-commands) to
   select the agent's Kubernetes context and run the Kubernetes API commands.
1. Run your pipeline to deploy to or update the cluster.

## Authorize the agent

If you have multiple GitLab projects, you must authorize the agent to access the project where you keep your Kubernetes manifests.
You can authorize the agent to access individual projects, or authorize a group or subgroup,
so all projects within have access. For added security, you can also
[use impersonation](#restrict-project-and-group-access-by-using-impersonation).

Authorization configuration can take one or two minutes to propagate.

### Authorize the agent to access your projects

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/346566) to remove hierarchy restrictions in GitLab 15.6.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/356831) to allow authorizing projects in a user namespace in GitLab 15.7.

To authorize the agent to access the GitLab project where you keep Kubernetes manifests:

1. On the left sidebar, select **Search or go to** and find the project that contains the [agent configuration file](install/_index.md#create-an-agent-configuration-file) (`config.yaml`).
1. Edit the `config.yaml` file. Under the `ci_access` keyword, add the `projects` attribute.
1. For the `id`, add the path to the project.

   ```yaml
   ci_access:
     projects:
       - id: path/to/project
   ```

   - Authorized projects must have the same top-level group or user namespace as the agent's configuration project.
   - You can install additional agents into the same cluster to accommodate additional hierarchies.
   - You can authorize up to 500 projects.

All CI/CD jobs now include a `kubeconfig` file with contexts for every shared agent connection.
The `kubeconfig` path is available in the environment variable `$KUBECONFIG`.
Choose the context to run `kubectl` commands from your CI/CD scripts.

### Authorize the agent to access projects in your groups

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/346566) to remove hierarchy restrictions in GitLab 15.6.

To authorize the agent to access all of the GitLab projects in a group or subgroup:

1. On the left sidebar, select **Search or go to** and find the project that contains the [agent configuration file](install/_index.md#create-an-agent-configuration-file) (`config.yaml`).
1. Edit the `config.yaml` file. Under the `ci_access` keyword, add the `groups` attribute.
1. For the `id`, add the path:

   ```yaml
   ci_access:
     groups:
       - id: path/to/group/subgroup
   ```

   - Authorized groups must have the same top-level group as the agent's configuration project.
   - You can install additional agents into the same cluster to accommodate additional hierarchies.
   - All of the subgroups of an authorized group also have access to the same agent (without being specified individually).
   - You can authorize up to 500 groups.

All the projects that belong to the group and its subgroups are now authorized to access the agent.
All CI/CD jobs now include a `kubeconfig` file with contexts for every shared agent connection.
The `kubeconfig` path is available in an environment variable `$KUBECONFIG`.
Choose the context to run `kubectl` commands from your CI/CD scripts.

## Update your `.gitlab-ci.yml` file to run `kubectl` commands

In the project where you want to run Kubernetes commands, edit your project's `.gitlab-ci.yml` file.

In the first command under the `script` keyword, set your agent's context.
Use the format `<path/to/agent/project>:<agent-name>`. For example:

```yaml
deploy:
  image:
    name: bitnami/kubectl:latest
    entrypoint: ['']
  script:
    - kubectl config get-contexts
    - kubectl config use-context path/to/agent/project:agent-name
    - kubectl get pods
```

If you are not sure what your agent's context is, run `kubectl config get-contexts` from a CI/CD job where you want to access the agent.

### Environments that use Auto DevOps

If Auto DevOps is enabled, you must define the CI/CD variable `KUBE_CONTEXT`.
Set the value of `KUBE_CONTEXT` to the context of the agent you want Auto DevOps to use:

```yaml
deploy:
  variables:
    KUBE_CONTEXT: path/to/agent/project:agent-name
```

You can assign different agents to separate Auto DevOps jobs. For instance,
Auto DevOps can use one agent for `staging` jobs, and another agent for `production` jobs.
To use multiple agents, define an [environment-scoped CI/CD variable](../../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)
for each agent. For example:

1. Define two variables named `KUBE_CONTEXT`.
1. For the first variable:
   1. Set the `environment` to `staging`.
   1. Set the value to the context of your staging agent.
1. For the second variable:
   1. Set the `environment` to `production`.
   1. Set the value to the context of your production agent.

### Environments with both certificate-based and agent-based connections

When you deploy to an environment that has both a
[certificate-based cluster](../../infrastructure/clusters/_index.md) (deprecated) and an agent connection:

- The certificate-based cluster's context is called `gitlab-deploy`. This context
  is always selected by default.
- Agent contexts are included in `$KUBECONFIG`.
  You can select them by using `kubectl config use-context <path/to/agent/project>:<agent-name>`.

To use an agent connection when certificate-based connections are present, you can manually configure a new `kubectl`
configuration context. For example:

```yaml
deploy:
  variables:
    KUBE_CONTEXT: my-context # The name to use for the new context
    AGENT_ID: 1234 # replace with your agent's numeric ID
    K8S_PROXY_URL: https://<KAS_DOMAIN>/k8s-proxy/ # For agent server (KAS) deployed in Kubernetes cluster (for gitlab.com use kas.gitlab.com); replace with your URL
    # K8S_PROXY_URL: https://<GITLAB_DOMAIN>/-/kubernetes-agent/k8s-proxy/ # For agent server (KAS) in Omnibus
    # ... any other variables you have configured
  before_script:
    - kubectl config set-credentials agent:$AGENT_ID --token="ci:${AGENT_ID}:${CI_JOB_TOKEN}"
    - kubectl config set-cluster gitlab --server="${K8S_PROXY_URL}"
    - kubectl config set-context "$KUBE_CONTEXT" --cluster=gitlab --user="agent:${AGENT_ID}"
    - kubectl config use-context "$KUBE_CONTEXT"
  # ... rest of your job configuration
```

### Environments with KAS that use self-signed certificates

If you use an environment with KAS and a self-signed certificate, you must configure your Kubernetes client to trust the certificate authority (CA) that signed your certificate.

To configure your client, do one of the following:

- Set a CI/CD variable `SSL_CERT_FILE` with the KAS certificate in PEM format.
- Configure the Kubernetes client with `--certificate-authority=$KAS_CERTIFICATE`, where `KAS_CERTIFICATE` is a CI/CD variable with the CA certificate of KAS.
- Place the certificates in an appropriate location in the job container by updating the container image or mounting via the runner.
- Not recommended. Configure the Kubernetes client with `--insecure-skip-tls-verify=true`.

## Restrict project and group access by using impersonation

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/357934) in GitLab 15.5 to add impersonation support for environment tiers.

By default, your CI/CD job inherits all the permissions from the service account used to install the
agent in the cluster.
To restrict access to your cluster, you can use [impersonation](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#user-impersonation).

To specify impersonations, use the `access_as` attribute in your agent configuration file and use Kubernetes RBAC rules to manage impersonated account permissions.

You can impersonate:

- The agent itself (default).
- The CI/CD job that accesses the cluster.
- A specific user or system account defined within the cluster.

Authorization configuration can take one or two minutes to propagate.

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
  - The slug and tier of the environment this job belongs to.

    Example: for a CI job in `group1/group1-1/project1` where:

    - Group `group1` has ID 23.
    - Group `group1/group1-1` has ID 25.
    - Project `group1/group1-1/project1` has ID 150.
    - Job running in the `prod` environment, which has the `production` environment tier.

  Group list would be `[gitlab:ci_job, gitlab:group:23, gitlab:group_env_tier:23:production, gitlab:group:25, gitlab:group_env_tier:25:production, gitlab:project:150, gitlab:project_env:150:prod, gitlab:project_env_tier:150:production]`.

- `Extra` carries extra information about the request. The following properties are set on the impersonated identity:

| Property                             | Description                                                                  |
| ------------------------------------ | ---------------------------------------------------------------------------- |
| `agent.gitlab.com/id`                | Contains the agent ID.                                                       |
| `agent.gitlab.com/config_project_id` | Contains the agent's configuration project ID.                               |
| `agent.gitlab.com/project_id`        | Contains the CI project ID.                                                  |
| `agent.gitlab.com/ci_pipeline_id`    | Contains the CI pipeline ID.                                                 |
| `agent.gitlab.com/ci_job_id`         | Contains the CI job ID.                                                      |
| `agent.gitlab.com/username`          | Contains the username of the user the CI job is running as.                  |
| `agent.gitlab.com/environment_slug`  | Contains the slug of the environment. Only set if running in an environment. |
| `agent.gitlab.com/environment_tier`  | Contains the tier of the environment. Only set if running in an environment. |

Example `config.yaml` to restrict access by the CI/CD job's identity:

```yaml
ci_access:
  projects:
    - id: path/to/project
      access_as:
        ci_job: {}
```

#### Example RBAC to restrict CI/CD jobs

The following `RoleBinding` resource restricts all CI/CD jobs to view rights only.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ci-job-view
roleRef:
  name: view
  kind: ClusterRole
  apiGroup: rbac.authorization.k8s.io
subjects:
  - name: gitlab:ci_job
    kind: Group
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

## Restrict project and group access to specific environments

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/343885) in GitLab 15.7.

By default, if your agent is [available to a project](#authorize-the-agent), all of the project's CI/CD jobs can use that agent.

To restrict access to the agent to only jobs with specific environments, add `environments` to `ci_access.projects` or `ci_access.groups`. For example:

  ```yaml
  ci_access:
    projects:
      - id: path/to/project-1
      - id: path/to/project-2
        environments:
          - staging
          - review/*
    groups:
      - id: path/to/group-1
        environments:
          - production
  ```

In this example:

- All CI/CD jobs under `project-1` can access the agent.
- CI/CD jobs under `project-2` with `staging` or `review/*` environments can access the agent.
  - `*` is a wildcard, so `review/*` matches all environments under `review`.
- CI/CD jobs for projects under `group-1` with `production` environments can access the agent.

## Restrict access to the agent to protected branches

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/467936) in GitLab 17.3 [with a flag](../../../administration/feature_flags.md) named `kubernetes_agent_protected_branches`. Disabled by default.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

To restrict access to the agent to only jobs run on [protected branches](../../project/repository/branches/protected.md):

- Add `protected_branches_only: true` to `ci_access.projects` or `ci_access.groups`.
  For example:

  ```yaml
  ci_access:
    projects:
      - id: path/to/project-1
        protected_branches_only: true
    groups:
      - id: path/to/group-1
        protected_branches_only: true
        environments:
          - production
  ```

By default, `protected_branches_only` is set to `false`, and the agent can be accessed from unprotected and protected branches.

For additional security, you can combine this feature with [environment restrictions](#restrict-project-and-group-access-to-specific-environments).

If a project has multiple configurations, only the most specific configuration is used.
For example, the following configuration grants access to unprotected branches in `example/my-project`, even though the `example` group is configured to grant access to only protected branches:

```yaml
# .gitlab/agents/my-agent/config.yaml
ci_access:
  project:
    - id: example/my-project # Project of the group below
      protected_branches_only: false # This configuration supercedes the group configuration
      environments:
        - dev
  groups:
    - id: example
      protected_branches_only: true
      environments:
        - dev
```

For more details, see [Access to Kubernetes from CI/CD](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kubernetes_ci_access.md#apiv4joballowed_agents-api).

## Related topics

- [Self-paced classroom workshop](https://gitlab-for-eks.awsworkshop.io) (Uses AWS EKS, but you can use for other Kubernetes clusters)
- [Configure Auto DevOps](../../../topics/autodevops/cloud_deployments/auto_devops_with_gke.md#configure-auto-devops)

## Troubleshooting

### Grant write permissions to `~/.kube/cache`

Tools like `kubectl`, Helm, `kpt`, and `kustomize` cache information about
the cluster in `~/.kube/cache`. If this directory is not writable, the tool fetches information on each invocation,
making interactions slower and creating unnecessary load on the cluster. For the best experience, in the
image you use in your `.gitlab-ci.yml` file, ensure this directory is writable.

### Enable TLS

If you are on GitLab Self-Managed, ensure your instance is configured with Transport Layer Security (TLS).

If you attempt to use `kubectl` without TLS, you might get an error like:

```shell
$ kubectl get pods
error: You must be logged in to the server (the server has asked for the client to provide credentials)
```

### Unable to connect to the server: certificate signed by unknown authority

If you use an environment with KAS and a self-signed certificate, your `kubectl` call might return this error:

```plaintext
kubectl get pods
Unable to connect to the server: x509: certificate signed by unknown authority
```

The error occurs because the job does not trust the certificate authority (CA) that signed the KAS certificate.

To resolve the issue, [configure `kubectl` to trust the CA](#environments-with-kas-that-use-self-signed-certificates).

### Validation errors

If you use `kubectl` versions v1.27.0 or v.1.27.1, you might get the following error:

```plaintext
error: error validating "file.yml": error validating data: the server responded with the status code 426 but did not return more information; if you choose to ignore these errors, turn validation off with --validate=false
```

This issue is caused by [a bug](https://github.com/kubernetes/kubernetes/issues/117463) with `kubectl` and other tools that use the shared Kubernetes libraries.

To resolve the issue, use another version of `kubectl`.
