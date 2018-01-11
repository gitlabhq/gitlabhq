# Connecting GitLab with a Kubernetes cluster

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/35954) in GitLab 10.1.

NOTE: **Note:**
The Cluster integration will eventually supersede the
[Kubernetes integration](../integrations/kubernetes.md).

With a cluster associated to your project, you can use Review Apps, deploy your
applications, run your pipelines, and much more, in an easy way.

Connect your project to Google Kubernetes Engine (GKE) or an existing Kubernetes
cluster in a few steps.

## Prerequisites

In order to be able to manage your Kubernetes cluster through GitLab, the
following prerequisites must be met.

**For a cluster hosted on GKE:**

- The [Google authentication integration](../../../integration/google.md) must
  be enabled in GitLab at the instance level. If that's not the case, ask your
  GitLab administrator to enable it.
- Your associated Google account must have the right privileges to manage
  clusters on GKE. That would mean that a [billing
  account](https://cloud.google.com/billing/docs/how-to/manage-billing-account)
  must be set up and that you have to have permissions to access it.
- You must have Master [permissions] in order to be able to access the
  **Cluster** page.
- You must have [Cloud Billing API](https://cloud.google.com/billing/) enabled
- You must have [Resource Manager
  API](https://cloud.google.com/resource-manager/)

**For an existing Kubernetes cluster:**

- Since the cluster is already created, there are no prerequisites.

---

If all of the above requirements are met, you can proceed to add a new Kubernetes
cluster.

## Adding a Kubernetes cluster

NOTE: **Note:**
You need Master [permissions] and above to access the Clusters page.

There are two options when adding a new cluster to your project; either associate
your account with Google Kubernetes Engine (GKE) so that you can create new
clusters from within GitLab, or provide the credentials to an existing
Kubernetes cluster.

Before proceeding to either method, make sure all [prerequisites](#prerequisites)
are met.

**To add a new cluster hosted on GKE to your project:**

1. Navigate to your project's **CI/CD > Clusters** page.
1. Click on **Add cluster**.
1. Click on **Create with GKE**.
1. Connect your Google account if you haven't done already by clicking the
   **Sign in with Google** button.
1. Fill in the requested values:
  - **Cluster name** (required) - The name you wish to give the cluster.
  - **GCP project ID** (required) - The ID of the project you created in your GCP
    console that will host the Kubernetes cluster. This must **not** be confused
    with the project name. Learn more about [Google Cloud Platform projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects).
  - **Zone** - The [zone](https://cloud.google.com/compute/docs/regions-zones/)
    under which the cluster will be created.
  - **Number of nodes** - The number of nodes you wish the cluster to have.
  - **Machine type** - The [machine type](https://cloud.google.com/compute/docs/machine-types)
    of the Virtual Machine instance that the cluster will be based on.
  - **Project namespace** - The unique namespace for this project. By default you
    don't have to fill it in; by leaving it blank, GitLab will create one for you.
  - **Environment scope** - The [associated environment](#setting-the-environment-scope) to this cluster.
1. Finally, click the **Create cluster** button.

---

**To add an existing cluster to your project:**

1. Navigate to your project's **CI/CD > Clusters** page.
1. Click on **Add cluster**.
1. Click on **Add an existing cluster** and fill in the details as described
   in the [Kubernetes integration](../integrations/kubernetes.md#configuration)
   documentation.
1. Select the [environment scope](#setting-the-environment-scope).
1. Finally, click the **Create cluster** button.

---

After a few moments, your cluster should be created. If something goes wrong,
you will be notified.

You can now proceed to install some pre-defined applications and then
enable the Cluster integration.

## Installing applications

GitLab provides a one-click install for various applications which will be
added directly to your configured cluster. Those applications are needed for
[Review Apps](../../../ci/review_apps/index.md) and [deployments](../../../ci/environments.md).

| Application | GitLab version | Description |
| ----------- | :------------: | ----------- |
| [Helm Tiller](https://docs.helm.sh/) | 10.2+ | Helm is a package manager for Kubernetes and is required to install all the other applications. It will be automatically installed as a dependency when you try to install a different app. It is installed in its own pod inside the cluster which can run the `helm` CLI in a safe environment. |
| [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) | 10.2+ | Ingress can provide load balancing, SSL termination, and name-based virtual hosting. It acts as a web proxy for your applications and is useful if you want to use [Auto DevOps](../../../topics/autodevops/index.md) or deploy your own web apps. |
| [Prometheus](https://prometheus.io/docs/introduction/overview/) | 10.4+ | Prometheus is an open-source monitoring and alerting system useful to supervise your deployed applications |

## Enabling or disabling the Cluster integration

After you have successfully added your cluster information, you can enable the
Cluster integration:

1. Click the "Enabled/Disabled" switch
1. Hit **Save** for the changes to take effect

You can now start using your Kubernetes cluster for your deployments.

To disable the Cluster integration, follow the same procedure.

## Removing the Cluster integration

NOTE: **Note:**
You need Master [permissions] and above to remove a cluster integration.

NOTE: **Note:**
When you remove a cluster, you only remove its relation to GitLab, not the
cluster itself. To remove the cluster, you can do so by visiting the GKE
dashboard or using `kubectl`.

To remove the Cluster integration from your project, simply click on the
**Remove integration** button. You will then be able to follow the procedure
and [add a cluster](#adding-a-cluster) again.

## Multiple Kubernetes clusters

> Introduced in [GitLab Enterprise Edition Premium][ee] 10.3.

With GitLab EEP, you can associate more than one Kubernetes clusters to your
project. That way you can have different clusters for different environments,
like dev, staging, production, etc.

To add another cluster, follow the same steps as described in [adding a
Kubernetes cluster](#adding-a-kubernetes-cluster) and make sure to
[set an environment scope](#setting-the-environment-scope) that will
differentiate the new cluster with the rest.

## Setting the environment scope

When adding more than one clusters, you need to differentiate them with an
environment scope. The environment scope associates clusters and
[environments](../../../ci/environments.md) in an 1:1 relationship similar to how the
[environment-specific variables](../../../ci/variables/README.md#limiting-environment-scopes-of-secret-variables)
work.

The default environment scope is `*`, which means all jobs, regardless of their
environment, will use that cluster. Each scope can only be used by a single
cluster in a project, and a validation error will occur if otherwise.

---

For example, let's say the following clusters exist in a project:

| Cluster    | Environment scope   |
| ---------- | ------------------- |
| Development| `*`                 |
| Staging    | `staging/*`         |
| Production | `production/*`      |

And the following environments are set in [`.gitlab-ci.yml`](../../../ci/yaml/README.md):

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
    name: staging/$CI_COMMIT_REF_NAME
    url: https://staging.example.com/

deploy to production:
  stage: deploy
  script: make deploy
  environment:
    name: production/$CI_COMMIT_REF_NAME
    url: https://example.com/
```

The result will then be:

- The development cluster will be used for the "test" job.
- The staging cluster will be used for the "deploy to staging" job.
- The production cluster will be used for the "deploy to production" job.

[permissions]: ../../permissions.md
[ee]: https://about.gitlab.com/gitlab-ee/
