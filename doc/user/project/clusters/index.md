---
stage: Monitor
group: Health
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Kubernetes clusters

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/35954) in GitLab 10.1 for projects.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/34758) in
>   GitLab 11.6 for [groups](../../group/clusters/index.md).
> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/39840) in
>   GitLab 11.11 for [instances](../../instance/clusters/index.md).

Using the GitLab project Kubernetes integration, you can:

- Use [Review Apps](../../../ci/review_apps/index.md).
- Run [pipelines](../../../ci/pipelines/index.md).
- [Deploy](#deploying-to-a-kubernetes-cluster) your applications.
- Detect and [monitor Kubernetes](#monitoring-your-kubernetes-cluster).
- Use it with [Auto DevOps](#auto-devops).
- Use [Web terminals](#web-terminals).
- Use [Deploy Boards](#deploy-boards). **(PREMIUM)**
- Use [Canary Deployments](#canary-deployments). **(PREMIUM)**
- Use [deployment variables](#deployment-variables).
- Use [role-based or attribute-based access controls](add_remove_clusters.md#access-controls).
- View [Logs](#viewing-pod-logs).
- Run serverless workloads on [Kubernetes with Knative](serverless/index.md).

Besides integration at the project level, Kubernetes clusters can also be
integrated at the [group level](../../group/clusters/index.md) or
[GitLab instance level](../../instance/clusters/index.md).

To view your project level Kubernetes clusters, navigate to **Operations > Kubernetes**
from your project. On this page, you can [add a new cluster](#adding-and-removing-clusters)
and view information about your existing clusters, such as nodes count and rough estimates
of memory and CPU usage.

## Setting up

### Supported cluster versions

GitLab is committed to support at least two production-ready Kubernetes minor
versions at any given time. We regularly review the versions we support, and
provide a three-month deprecation period before we remove support of a specific
version. The range of supported versions is based on the evaluation of:

- Our own needs.
- The versions supported by major managed Kubernetes providers.
- The versions [supported by the Kubernetes community](https://kubernetes.io/docs/setup/release/version-skew-policy/#supported-versions).

GitLab supports the following Kubernetes versions, and you can upgrade your
Kubernetes version to any supported version at any time:

- 1.18
- 1.17
- 1.16
- 1.15
- 1.14 (deprecated, support ends on December 22, 2020)

Some GitLab features may support versions outside the range provided here.

### Adding and removing clusters

See [Adding and removing Kubernetes clusters](add_remove_clusters.md) for details on how
to:

- Create a cluster in Google Cloud Platform (GCP) or Amazon Elastic Kubernetes Service
  (EKS) using GitLab's UI.
- Add an integration to an existing cluster from any Kubernetes platform.

### Multiple Kubernetes clusters

> - Introduced in [GitLab Premium](https://about.gitlab.com/pricing/) 10.3
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/35094) to GitLab Core in 13.2.

You can associate more than one Kubernetes cluster to your
project. That way you can have different clusters for different environments,
like dev, staging, production, and so on.

Simply add another cluster, like you did the first time, and make sure to
[set an environment scope](#setting-the-environment-scope) that
differentiates the new cluster from the rest.

#### Setting the environment scope

When adding more than one Kubernetes cluster to your project, you need to differentiate
them with an environment scope. The environment scope associates clusters with [environments](../../../ci/environments/index.md) similar to how the
[environment-specific variables](../../../ci/variables/README.md#limit-the-environment-scopes-of-environment-variables) work.

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
[`.gitlab-ci.yml`](../../../ci/yaml/README.md):

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

## Configuring your Kubernetes cluster

After [adding a Kubernetes cluster](add_remove_clusters.md) to GitLab, read this section that covers
important considerations for configuring Kubernetes clusters with GitLab.

### Security implications

CAUTION: **Important:**
The whole cluster security is based on a model where [developers](../../permissions.md)
are trusted, so **only trusted users should be allowed to control your clusters**.

The default cluster configuration grants access to a wide set of
functionalities needed to successfully build and deploy a containerized
application. Bear in mind that the same credentials are used for all the
applications running on the cluster.

### GitLab-managed clusters

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/22011) in GitLab 11.5.
> - Became [optional](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/26565) in GitLab 11.11.

You can choose to allow GitLab to manage your cluster for you. If your cluster
is managed by GitLab, resources for your projects are automatically created. See
the [Access controls](add_remove_clusters.md#access-controls) section for
details about the created resources.

If you choose to manage your own cluster, project-specific resources aren't created
automatically. If you are using [Auto DevOps](../../../topics/autodevops/index.md), you must
explicitly provide the `KUBE_NAMESPACE` [deployment variable](#deployment-variables)
for your deployment jobs to use; otherwise a namespace is created for you.

#### Important notes

Note the following with GitLab and clusters:

- If you [install applications](#installing-applications) on your cluster, GitLab will
  create the resources required to run these even if you have chosen to manage your own
  cluster.
- Be aware that manually managing resources that have been created by GitLab, like
  namespaces and service accounts, can cause unexpected errors. If this occurs, try
  [clearing the cluster cache](#clearing-the-cluster-cache).

#### Clearing the cluster cache

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/31759) in GitLab 12.6.

If you choose to allow GitLab to manage your cluster for you, GitLab stores a cached
version of the namespaces and service accounts it creates for your projects. If you
modify these resources in your cluster manually, this cache can fall out of sync with
your cluster, which can cause deployment jobs to fail.

To clear the cache:

1. Navigate to your project’s **Operations > Kubernetes** page, and select your cluster.
1. Expand the **Advanced settings** section.
1. Click **Clear cluster cache**.

### Base domain

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/24580) in GitLab 11.8.

You do not need to specify a base domain on cluster settings when using GitLab Serverless. The domain in that case
is specified as part of the Knative installation. See [Installing Applications](#installing-applications).

Specifying a base domain automatically sets `KUBE_INGRESS_BASE_DOMAIN` as an environment variable.
If you are using [Auto DevOps](../../../topics/autodevops/index.md), this domain is used for the different
stages. For example, Auto Review Apps and Auto Deploy.

The domain should have a wildcard DNS configured to the Ingress IP address. After Ingress has been installed (see [Installing Applications](#installing-applications)),
you can either:

- Create an `A` record that points to the Ingress IP address with your domain provider.
- Enter a wildcard DNS address using a service such as nip.io or xip.io. For example, `192.168.1.1.xip.io`.

## Installing applications

GitLab can install and manage some applications like Helm, GitLab Runner, Ingress,
Prometheus, and so on, in your project-level cluster. For more information on
installing, upgrading, uninstalling, and troubleshooting applications for
your project cluster, see
[GitLab Managed Apps](../../clusters/applications.md).

## Auto DevOps

Auto DevOps automatically detects, builds, tests, deploys, and monitors your
applications.

To make full use of Auto DevOps (Auto Deploy, Auto Review Apps, and
Auto Monitoring) the Kubernetes project integration must be enabled, but
Kubernetes clusters can be used without Auto DevOps.

[Read more about Auto DevOps](../../../topics/autodevops/index.md)

## Deploying to a Kubernetes cluster

A Kubernetes cluster can be the destination for a deployment job. If

- The cluster is integrated with GitLab, special
  [deployment variables](#deployment-variables) are made available to your job
  and configuration is not required. You can immediately begin interacting with
  the cluster from your jobs using tools such as `kubectl` or `helm`.
- You don't use GitLab's cluster integration you can still deploy to your
  cluster. However, you must configure Kubernetes tools yourself
  using [environment variables](../../../ci/variables/README.md#custom-environment-variables)
  before you can interact with the cluster from your jobs.

### Deployment variables

Deployment variables require a valid [Deploy Token](../deploy_tokens/index.md) named
[`gitlab-deploy-token`](../deploy_tokens/index.md#gitlab-deploy-token), and the
following command in your deployment job script, for Kubernetes to access the registry:

```plaintext
kubectl create secret docker-registry gitlab-registry --docker-server="$CI_REGISTRY" --docker-username="$CI_DEPLOY_USER" --docker-password="$CI_DEPLOY_PASSWORD" --docker-email="$GITLAB_USER_EMAIL" -o yaml --dry-run | kubectl apply -f -
```

The Kubernetes cluster integration exposes the following
[deployment variables](../../../ci/variables/README.md#deployment-environment-variables) in the
GitLab CI/CD build environment to deployment jobs, which are jobs that have
[defined a target environment](../../../ci/environments/index.md#defining-environments).

| Variable                   | Description |
|----------------------------|-------------|
| `KUBE_URL`                 | Equal to the API URL. |
| `KUBE_TOKEN`               | The Kubernetes token of the [environment service account](add_remove_clusters.md#access-controls). Prior to GitLab 11.5, `KUBE_TOKEN` was the Kubernetes token of the main service account of the cluster integration. |
| `KUBE_NAMESPACE`           | The namespace associated with the project's deployment service account. In the format `<project_name>-<project_id>-<environment>`. For GitLab-managed clusters, a matching namespace is automatically created by GitLab in the cluster. If your cluster was created before GitLab 12.2, the default `KUBE_NAMESPACE` is set to `<project_name>-<project_id>`. |
| `KUBE_CA_PEM_FILE`         | Path to a file containing PEM data. Only present if a custom CA bundle was specified. |
| `KUBE_CA_PEM`              | (**deprecated**) Raw PEM data. Only if a custom CA bundle was specified. |
| `KUBECONFIG`               | Path to a file containing `kubeconfig` for this deployment. CA bundle would be embedded if specified. This configuration also embeds the same token defined in `KUBE_TOKEN` so you likely need only this variable. This variable name is also automatically picked up by `kubectl` so you don't need to reference it explicitly if using `kubectl`. |
| `KUBE_INGRESS_BASE_DOMAIN` | From GitLab 11.8, this variable can be used to set a domain per cluster. See [cluster domains](#base-domain) for more information. |

### Custom namespace

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/27630) in GitLab 12.6.
> - An option to use project-wide namespaces [was added](https://gitlab.com/gitlab-org/gitlab/-/issues/38054) in GitLab 13.5.

The Kubernetes integration provides a `KUBECONFIG` with an auto-generated namespace
to deployment jobs. It defaults to using project-environment specific namespaces
of the form `<prefix>-<environment>`, where `<prefix>` is of the form
`<project_name>-<project_id>`. To learn more, read [Deployment variables](#deployment-variables).

You can customize the deployment namespace in a few ways:

- You can choose between a **namespace per [environment](../../../ci/environments/index.md)**
  or a **namespace per project**. A namespace per environment is the default and recommended
  setting, as it prevents the mixing of resources between production and non-production environments.
- When using a project-level cluster, you can additionally customize the namespace prefix.
  When using namespace-per-environment, the deployment namespace is `<prefix>-<environment>`,
  but otherwise just `<prefix>`.
- For **non-managed** clusters, the auto-generated namespace is set in the `KUBECONFIG`,
  but the user is responsible for ensuring its existence. You can fully customize
  this value using
  [`environment:kubernetes:namespace`](../../../ci/environments/index.md#configuring-kubernetes-deployments)
  in `.gitlab-ci.yml`.

When you customize the namespace, existing environments remain linked to their current
namespaces until you [clear the cluster cache](#clearing-the-cluster-cache).

CAUTION: **Warning:**
By default, anyone who can create a deployment job can access any CI variable within
an environment's deployment job. This includes `KUBECONFIG`, which gives access to
any secret available to the associated service account in your cluster.
To keep your production credentials safe, consider using
[Protected Environments](../../../ci/environments/protected_environments.md),
combined with either

- a GitLab-managed cluster and namespace per environment,
- *or*, an environment-scoped cluster per protected environment. The same cluster
  can be added multiple times with multiple restricted service accounts.

### Integrations

#### Canary Deployments **(PREMIUM)**

Leverage [Kubernetes' Canary deployments](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#canary-deployments)
and visualize your canary deployments right inside the Deploy Board, without
the need to leave GitLab.

[Read more about Canary Deployments](../canary_deployments.md)

#### Deploy Boards **(PREMIUM)**

GitLab's Deploy Boards offer a consolidated view of the current health and
status of each CI [environment](../../../ci/environments/index.md) running on Kubernetes,
displaying the status of the pods in the deployment. Developers and other
teammates can view the progress and status of a rollout, pod by pod, in the
workflow they already use without any need to access Kubernetes.

[Read more about Deploy Boards](../deploy_boards.md)

#### Viewing pod logs

GitLab makes it easy to view the logs of running pods in connected Kubernetes
clusters. By displaying the logs directly in GitLab, developers can avoid having
to manage console tools or jump to a different interface.

[Read more about Kubernetes logs](kubernetes_pod_logs.md)

#### Web terminals

> Introduced in GitLab 8.15.

When enabled, the Kubernetes integration adds [web terminal](../../../ci/environments/index.md#web-terminals)
support to your [environments](../../../ci/environments/index.md). This is based
on the `exec` functionality found in Docker and Kubernetes, so you get a new
shell session within your existing containers. To use this integration, you
should deploy to Kubernetes using the deployment variables above, ensuring any
deployments, replica sets, and pods are annotated with:

- `app.gitlab.com/env: $CI_ENVIRONMENT_SLUG`
- `app.gitlab.com/app: $CI_PROJECT_PATH_SLUG`

`$CI_ENVIRONMENT_SLUG` and `$CI_PROJECT_PATH_SLUG` are the values of
the CI variables.

You must be the project owner or have `maintainer` permissions to use terminals.
Support is limited to the first container in the first pod of your environment.

### Troubleshooting

Before the deployment jobs starts, GitLab creates the following specifically for
the deployment job:

- A namespace.
- A service account.

However, sometimes GitLab can not create them. In such instances, your job can fail with the message:

```plaintext
This job failed because the necessary resources were not successfully created.
```

To find the cause of this error when creating a namespace and service account, check the [logs](../../../administration/logs.md#kuberneteslog).

Reasons for failure include:

- The token you gave GitLab does not have [`cluster-admin`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles)
  privileges required by GitLab.
- Missing `KUBECONFIG` or `KUBE_TOKEN` variables. To be passed to your job, they must have a matching
  [`environment:name`](../../../ci/environments/index.md#defining-environments). If your job has no
  `environment:name` set, the Kubernetes credentials are not passed to it.

NOTE: **Note:**
Project-level clusters upgraded from GitLab 12.0 or older may be configured
in a way that causes this error. Ensure you deselect the
[GitLab-managed cluster](#gitlab-managed-clusters) option if you want to manage
namespaces and service accounts yourself.

## Monitoring your Kubernetes cluster

Automatically detect and monitor Kubernetes metrics. Automatic monitoring of
[NGINX Ingress](../integrations/prometheus_library/nginx.md) is also supported.

[Read more about Kubernetes monitoring](../integrations/prometheus_library/kubernetes.md)

### Visualizing cluster health

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/4701) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.6.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/208224) to GitLab Core in 13.2.

When [Prometheus is deployed](#installing-applications), GitLab monitors the cluster's health. At the top of the cluster settings page, CPU and Memory utilization is displayed, along with the total amount available. Keeping an eye on cluster resources can be important, if the cluster runs out of memory pods may be shutdown or fail to start.

![Cluster Monitoring](img/k8s_cluster_monitoring.png)
