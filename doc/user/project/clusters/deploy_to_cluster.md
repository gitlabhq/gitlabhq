---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Deploy to a Kubernetes cluster with cluster certificates (deprecated)
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed

> - [Deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.

WARNING:
This feature was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.
To connect your cluster to GitLab, use the [GitLab agent](../../clusters/agent/_index.md).
To deploy with the agent, use the [CI/CD workflow](../../clusters/agent/ci_cd_workflow.md).

A Kubernetes cluster can be the destination for a deployment job. If

- The cluster is integrated with GitLab, special
  [deployment variables](#deployment-variables) are made available to your job
  and configuration is not required. You can immediately begin interacting with
  the cluster from your jobs using tools such as `kubectl` or `helm`.
- You don't use the GitLab cluster integration, you can still deploy to your
  cluster. However, you must configure Kubernetes tools yourself
  using [CI/CD variables](../../../ci/variables/_index.md#for-a-project)
  before you can interact with the cluster from your jobs.

## Deployment variables

Deployment variables require a valid [Deploy Token](../deploy_tokens/_index.md) named
[`gitlab-deploy-token`](../deploy_tokens/_index.md#gitlab-deploy-token), and the
following command in your deployment job script, for Kubernetes to access the registry:

- Using Kubernetes 1.18+:

  ```shell
  kubectl create secret docker-registry gitlab-registry --docker-server="$CI_REGISTRY" --docker-username="$CI_DEPLOY_USER" --docker-password="$CI_DEPLOY_PASSWORD" --docker-email="$GITLAB_USER_EMAIL" -o yaml --dry-run=client | kubectl apply -f -
  ```

- Using Kubernetes <1.18:

  ```shell
  kubectl create secret docker-registry gitlab-registry --docker-server="$CI_REGISTRY" --docker-username="$CI_DEPLOY_USER" --docker-password="$CI_DEPLOY_PASSWORD" --docker-email="$GITLAB_USER_EMAIL" -o yaml --dry-run | kubectl apply -f -
  ```

The Kubernetes cluster integration exposes these
[deployment variables](../../../ci/variables/predefined_variables.md#deployment-variables) in the
GitLab CI/CD build environment to deployment jobs. Deployment jobs have
[defined a target environment](../../../ci/environments/_index.md).

| Deployment Variable        | Description |
|----------------------------|-------------|
| `KUBE_URL`                 | Equal to the API URL. |
| `KUBE_TOKEN`               | The Kubernetes token of the [environment service account](cluster_access.md). |
| `KUBE_NAMESPACE`           | The namespace associated with the project's deployment service account. In the format `<project_name>-<project_id>-<environment>`. For GitLab-managed clusters, a matching namespace is automatically created by GitLab in the cluster. If your cluster was created before GitLab 12.2, the default `KUBE_NAMESPACE` is set to `<project_name>-<project_id>`. |
| `KUBE_CA_PEM_FILE`         | Path to a file containing PEM data. Only present if a custom CA bundle was specified. |
| `KUBE_CA_PEM`              | (**deprecated**) Raw PEM data. Only if a custom CA bundle was specified. |
| `KUBECONFIG`               | Path to a file containing `kubeconfig` for this deployment. CA bundle would be embedded if specified. This configuration also embeds the same token defined in `KUBE_TOKEN` so you likely need only this variable. This variable name is also automatically picked up by `kubectl` so you don't need to reference it explicitly if using `kubectl`. |
| `KUBE_INGRESS_BASE_DOMAIN` | This variable can be used to set a domain per cluster. See [cluster domains](gitlab_managed_clusters.md#base-domain) for more information. |

## Custom namespace

The Kubernetes integration provides a `KUBECONFIG` with an auto-generated namespace
to deployment jobs. It defaults to using project-environment specific namespaces
of the form `<prefix>-<environment>`, where `<prefix>` is of the form
`<project_name>-<project_id>`. For more information, see [Deployment variables](#deployment-variables).

You can customize the deployment namespace in a few ways:

- You can choose between a **namespace per [environment](../../../ci/environments/_index.md)**
  or a **namespace per project**. A namespace per environment is the default and recommended
  setting, as it prevents the mixing of resources between production and non-production environments.
- When using a project-level cluster, you can additionally customize the namespace prefix.
  When using namespace-per-environment, the deployment namespace is `<prefix>-<environment>`,
  but otherwise just `<prefix>`.
- For **non-managed** clusters, the auto-generated namespace is set in the `KUBECONFIG`,
  but the user is responsible for ensuring its existence. You can fully customize
  this value using
  [`environment:kubernetes:namespace`](../../../ci/environments/configure_kubernetes_deployments.md)
  in `.gitlab-ci.yml`.

When you customize the namespace, existing environments remain linked to their current
namespaces until you [clear the cluster cache](gitlab_managed_clusters.md#clearing-the-cluster-cache).

### Protecting credentials

By default, anyone who can create a deployment job can access any CI/CD variable in
an environment's deployment job. This includes `KUBECONFIG`, which gives access to
any secret available to the associated service account in your cluster.
To keep your production credentials safe, consider using
[protected environments](../../../ci/environments/protected_environments.md),
combined with *one* of the following:

- A GitLab-managed cluster and namespace per environment.
- An environment-scoped cluster per protected environment. The same cluster
  can be added multiple times with multiple restricted service accounts.

## Web terminals for Kubernetes clusters

The Kubernetes integration adds [web terminal](../../../ci/environments/_index.md#web-terminals-deprecated)
support to your [environments](../../../ci/environments/_index.md). This is based
on the `exec` functionality found in Docker and Kubernetes, so you get a new
shell session in your existing containers. To use this integration, you
should deploy to Kubernetes using the deployment variables above, ensuring any
deployments, replica sets, and pods are annotated with:

- `app.gitlab.com/env: $CI_ENVIRONMENT_SLUG`
- `app.gitlab.com/app: $CI_PROJECT_PATH_SLUG`

`$CI_ENVIRONMENT_SLUG` and `$CI_PROJECT_PATH_SLUG` are the values of
the CI/CD variables.

You must be the project owner or have `maintainer` permissions to use terminals.
Support is limited to the first container in the first pod of your environment.

## Troubleshooting

Before the deployment jobs starts, GitLab creates the following specifically for
the deployment job:

- A namespace.
- A service account.

However, sometimes GitLab cannot create them. In such instances, your job can fail with the message:

```plaintext
This job failed because the necessary resources were not successfully created.
```

To find the cause of this error when creating a namespace and service account, check the [logs](../../../administration/logs/_index.md#kuberneteslog-deprecated).

Reasons for failure include:

- The token you gave GitLab does not have [`cluster-admin`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles)
  privileges required by GitLab.
- Missing `KUBECONFIG` or `KUBE_TOKEN` deployment variables. To be passed to your job, they must have a matching
  [`environment:name`](../../../ci/environments/_index.md). If your job has no
  `environment:name` set, the Kubernetes credentials are not passed to it.

NOTE:
Project-level clusters upgraded from GitLab 12.0 or older may be configured
in a way that causes this error. Ensure you clear the
[GitLab-managed cluster](gitlab_managed_clusters.md) option if you want to manage
namespaces and service accounts yourself.
