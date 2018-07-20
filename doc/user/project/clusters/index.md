# Connecting GitLab with a Kubernetes cluster

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/35954) in GitLab 10.1.

Connect your project to Google Kubernetes Engine (GKE) or an existing Kubernetes
cluster in a few steps.

## Overview

With one or more Kubernetes clusters associated to your project, you can use
[Review Apps](../../../ci/review_apps/index.md), deploy your applications, run
your pipelines, use it with [Auto DevOps](../../../topics/autodevops/index.md),
and much more, all from within GitLab.

There are two options when adding a new cluster to your project; either associate
your account with Google Kubernetes Engine (GKE) so that you can [create new
clusters](#adding-and-creating-a-new-gke-cluster-via-gitlab) from within GitLab,
or provide the credentials to an [existing Kubernetes cluster](#adding-an-existing-kubernetes-cluster).

## Adding and creating a new GKE cluster via GitLab

TIP: **Tip:**
Every new Google Cloud Platform (GCP) account receives [$300 in credit upon sign up](https://console.cloud.google.com/freetrial),
and in partnership with Google, GitLab is able to offer an additional $200 for new GCP accounts to get started with GitLab's
Google Kubernetes Engine Integration. All you have to do is [follow this link](https://goo.gl/AaJzRW) and apply for credit.

NOTE: **Note:**
The [Google authentication integration](../../../integration/google.md) must
be enabled in GitLab at the instance level. If that's not the case, ask your
GitLab administrator to enable it. On GitLab.com, this is enabled.

### Requirements

Before creating your first cluster on Google Kubernetes Engine with GitLab's
integration, make sure the following requirements are met:

- A [billing account](https://cloud.google.com/billing/docs/how-to/manage-billing-account)
  is set up and you have permissions to access it.
- The Kubernetes Engine API is enabled. Follow the steps as outlined in the
  ["Before you begin" section of the Kubernetes Engine docs](https://cloud.google.com/kubernetes-engine/docs/quickstart#before-you-begin).

### Creating the cluster

If all of the above requirements are met, you can proceed to create and add a
new Kubernetes cluster to your project:

1. Navigate to your project's **Operations > Kubernetes** page.

    NOTE: **Note:**
    You need Maintainer [permissions] and above to access the Kubernetes page.

1. Click on **Add Kubernetes cluster**.
1. Click on **Create with Google Kubernetes Engine**.
1. Connect your Google account if you haven't done already by clicking the
   **Sign in with Google** button.
1. From there on, choose your cluster's settings:
  - **Kubernetes cluster name** - The name you wish to give the cluster.
  - **Environment scope** - The [associated environment](#setting-the-environment-scope) to this cluster.
  - **Google Cloud Platform project** - Choose the project you created in your GCP
    console that will host the Kubernetes cluster. Learn more about
    [Google Cloud Platform projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects).
  - **Zone** - Choose the [region zone](https://cloud.google.com/compute/docs/regions-zones/)
    under which the cluster will be created.
  - **Number of nodes** - Enter the number of nodes you wish the cluster to have.
  - **Machine type** - The [machine type](https://cloud.google.com/compute/docs/machine-types)
    of the Virtual Machine instance that the cluster will be based on.
1. Finally, click the **Create Kubernetes cluster** button.

After a couple of minutes, your cluster will be ready to go. You can now proceed
to install some [pre-defined applications](#installing-applications).

## Adding an existing Kubernetes cluster

To add an existing Kubernetes cluster to your project:

1. Navigate to your project's **Operations > Kubernetes** page.

    NOTE: **Note:**
    You need Maintainer [permissions] and above to access the Kubernetes page.

1. Click on **Add Kubernetes cluster**.
1. Click on **Add an existing Kubernetes cluster** and fill in the details:
    - **Kubernetes cluster name** (required) - The name you wish to give the cluster.
    - **Environment scope** (required)- The
      [associated environment](#setting-the-environment-scope) to this cluster.
    - **API URL** (required) -
      It's the URL that GitLab uses to access the Kubernetes API. Kubernetes
      exposes several APIs, we want the "base" URL that is common to all of them,
      e.g., `https://kubernetes.example.com` rather than `https://kubernetes.example.com/api/v1`.
    - **CA certificate** (optional) -
      If the API is using a self-signed TLS certificate, you'll also need to include
      the `ca.crt` contents here.
    - **Token** -
      GitLab authenticates against Kubernetes using service tokens, which are
      scoped to a particular `namespace`. If you don't have a service token yet,
      you can follow the
      [Kubernetes documentation](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
      to create one. You can also view or create service tokens in the
      [Kubernetes dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
      (under **Config > Secrets**). **The account that will issue the service token
      must have admin privileges on the cluster.**
    - **Project namespace** (optional) - You don't have to fill it in; by leaving
      it blank, GitLab will create one for you. Also:
      - Each project should have a unique namespace.
      - The project namespace is not necessarily the namespace of the secret, if
        you're using a secret with broader permissions, like the secret from `default`.
      - You should **not** use `default` as the project namespace.
      - If you or someone created a secret specifically for the project, usually
        with limited permissions, the secret's namespace and project namespace may
        be the same.
1. Finally, click the **Create Kubernetes cluster** button.

After a couple of minutes, your cluster will be ready to go. You can now proceed
to install some [pre-defined applications](#installing-applications).

## Security implications

CAUTION: **Important:**
The whole cluster security is based on a model where [developers](../../permissions.md)
are trusted, so **only trusted users should be allowed to control your clusters**.

The default cluster configuration grants access to a wide set of
functionalities needed to successfully build and deploy a containerized
application. Bare in mind that the same credentials are used for all the
applications running on the cluster.

When GitLab creates the cluster, it enables and uses the legacy
[Attribute-based access control (ABAC)](https://kubernetes.io/docs/admin/authorization/abac/).
The newer [RBAC](https://kubernetes.io/docs/admin/authorization/rbac/)
authorization will be supported in a
[future release](https://gitlab.com/gitlab-org/gitlab-ce/issues/29398).

### Security of GitLab Runners

GitLab Runners have the [privileged mode](https://docs.gitlab.com/runner/executors/docker.html#the-privileged-mode)
enabled by default, which allows them to execute special commands and running
Docker in Docker. This functionality is needed to run some of the [Auto DevOps]
jobs. This implies the containers are running in privileged mode and you should,
therefore, be aware of some important details.

The privileged flag gives all capabilities to the running container, which in
turn can do almost everything that the host can do. Be aware of the
inherent security risk associated with performing `docker run` operations on
arbitrary images as they effectively have root access.

If you don't want to use GitLab Runner in privileged mode, first make sure that
you don't have it installed via the applications, and then use the
[Runner's Helm chart](../../../install/kubernetes/gitlab_runner_chart.md) to
install it manually.

## Installing applications

GitLab provides a one-click install for various applications which will be
added directly to your configured cluster. Those applications are needed for
[Review Apps](../../../ci/review_apps/index.md) and [deployments](../../../ci/environments.md).

NOTE: **Note:**
The applications will be installed in a dedicated namespace called
`gitlab-managed-apps`. In case you have added an existing Kubernetes cluster
with Tiller already installed, you should be careful as GitLab cannot
detect it. By installing it via the applications will result into having it
twice, which can lead to confusion during deployments.

| Application | GitLab version | Description |
| ----------- | :------------: | ----------- |
| [Helm Tiller](https://docs.helm.sh/) | 10.2+ | Helm is a package manager for Kubernetes and is required to install all the other applications. It is installed in its own pod inside the cluster which can run the `helm` CLI in a safe environment. |
| [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) | 10.2+ | Ingress can provide load balancing, SSL termination, and name-based virtual hosting. It acts as a web proxy for your applications and is useful if you want to use [Auto DevOps] or deploy your own web apps. |
| [Prometheus](https://prometheus.io/docs/introduction/overview/) | 10.4+ | Prometheus is an open-source monitoring and alerting system useful to supervise your deployed applications. |
| [GitLab Runner](https://docs.gitlab.com/runner/) | 10.6+ | GitLab Runner is the open source project that is used to run your jobs and send the results back to GitLab. It is used in conjunction with [GitLab CI/CD](https://about.gitlab.com/features/gitlab-ci-cd/), the open-source continuous integration service included with GitLab that coordinates the jobs. When installing the GitLab Runner via the applications, it will run in **privileged mode** by default. Make sure you read the [security implications](#security-implications) before doing so. |
| [JupyterHub](http://jupyter.org/) | 11.0+ | [JupyterHub](https://jupyterhub.readthedocs.io/en/stable/) is a multi-user service for managing notebooks across a team. [Jupyter Notebooks](https://jupyter-notebook.readthedocs.io/en/latest/) provide a web-based interactive programming environment used for data analysis, visualization, and machine learning. We use [this](https://gitlab.com/gitlab-org/jupyterhub-user-image/blob/master/Dockerfile) custom Jupyter image that installs additional useful packages on top of the base Jupyter. **Note**: Authentication will be enabled for any user of the GitLab server via OAuth2. HTTPS will be supported in a future release. |

## Getting the external IP address

NOTE: **Note:**
You need a load balancer installed in your cluster in order to obtain the
external IP address with the following procedure. It can be deployed using the
[**Ingress** application](#installing-applications).

In order to publish your web application, you first need to find the external IP
address associated to your load balancer.

### Let GitLab fetch the IP address

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/17052) in GitLab 10.6.

If you installed the Ingress [via the **Applications**](#installing-applications),
you should see the Ingress IP address on this same page within a few minutes.
If you don't see this, GitLab might not be able to determine the IP address of
your ingress application in which case you should manually determine it.

### Manually determining the IP address

If the cluster is on GKE, click on the **Google Kubernetes Engine** link in the
**Advanced settings**, or go directly to the
[Google Kubernetes Engine dashboard](https://console.cloud.google.com/kubernetes/)
and select the proper project and cluster. Then click on **Connect** and execute
the `gcloud` command in a local terminal or using the **Cloud Shell**.

If the cluster is not on GKE, follow the specific instructions for your
Kubernetes provider to configure `kubectl` with the right credentials.

If you installed the Ingress [via the **Applications**](#installing-applications),
run the following command:

```bash
kubectl get svc --namespace=gitlab-managed-apps ingress-nginx-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip} '
```

Otherwise, you can list the IP addresses of all load balancers:

```bash
kubectl get svc --all-namespaces -o jsonpath='{range.items[?(@.status.loadBalancer.ingress)]}{.status.loadBalancer.ingress[*].ip} '
```

> **Note**: Some Kubernetes clusters return a hostname instead, like [Amazon EKS](https://aws.amazon.com/eks/). For these platforms, run:
> ```bash
> kubectl get service ingress-nginx-ingress-controller -n gitlab-managed-apps -o jsonpath="{.status.loadBalancer.ingress[0].hostname}".
> ```

The output is the external IP address of your cluster. This information can then
be used to set up DNS entries and forwarding rules that allow external access to
your deployed applications.

### Using a static IP

By default, an ephemeral external IP address is associated to the cluster's load
balancer. If you associate the ephemeral IP with your DNS and the IP changes,
your apps will not be able to be reached, and you'd have to change the DNS
record again. In order to avoid that, you should change it into a static
reserved IP.

[Read how to promote an ephemeral external IP address in GKE.](https://cloud.google.com/compute/docs/ip-addresses/reserve-static-external-ip-address#promote_ephemeral_ip)

### Pointing your DNS at the cluster IP

Once you've set up the static IP, you should associate it to a [wildcard DNS
record](https://en.wikipedia.org/wiki/Wildcard_DNS_record), in order to be able
to reach your apps. This heavily depends on your domain provider, but in case
you aren't sure, just create an A record with a wildcard host like
`*.example.com.`.

## Setting the environment scope

NOTE: **Note:**
This is only available for [GitLab Premium][ee] where you can add more than
one Kubernetes cluster.

When adding more than one Kubernetes clusters to your project, you need to
differentiate them with an environment scope. The environment scope associates
clusters and [environments](../../../ci/environments.md) in an 1:1 relationship
similar to how the
[environment-specific variables](../../../ci/variables/README.md#limiting-environment-scopes-of-variables)
work.

The default environment scope is `*`, which means all jobs, regardless of their
environment, will use that cluster. Each scope can only be used by a single
cluster in a project, and a validation error will occur if otherwise.
Also, jobs that don't have an environment keyword set will not be able to access any cluster.

---

For example, let's say the following Kubernetes clusters exist in a project:

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

## Multiple Kubernetes clusters

> Introduced in [GitLab Premium][ee] 10.3.

With GitLab Premium, you can associate more than one Kubernetes clusters to your
project. That way you can have different clusters for different environments,
like dev, staging, production, etc.

Simply add another cluster, like you did the first time, and make sure to
[set an environment scope](#setting-the-environment-scope) that will
differentiate the new cluster with the rest.

## Deployment variables

The Kubernetes cluster integration exposes the following
[deployment variables](../../../ci/variables/README.md#deployment-variables) in the
GitLab CI/CD build environment.

| Variable | Description |
| -------- | ----------- |
| `KUBE_URL` | Equal to the API URL. |
| `KUBE_TOKEN` | The Kubernetes token. |
| `KUBE_NAMESPACE` | The Kubernetes namespace is auto-generated if not specified. The default value is `<project_name>-<project_id>`. You can overwrite it to use different one if needed, otherwise the `KUBE_NAMESPACE` variable will receive the default value. |
| `KUBE_CA_PEM_FILE` | Only present if a custom CA bundle was specified. Path to a file containing PEM data. |
| `KUBE_CA_PEM` | (**deprecated**) Only if a custom CA bundle was specified. Raw PEM data. |
| `KUBECONFIG` | Path to a file containing `kubeconfig` for this deployment. CA bundle would be embedded if specified. |

## Enabling or disabling the Kubernetes cluster integration

After you have successfully added your cluster information, you can enable the
Kubernetes cluster integration:

1. Click the "Enabled/Disabled" switch
1. Hit **Save** for the changes to take effect

You can now start using your Kubernetes cluster for your deployments.

To disable the Kubernetes cluster integration, follow the same procedure.

## Removing the Kubernetes cluster integration

NOTE: **Note:**
You need Maintainer [permissions] and above to remove a Kubernetes cluster integration.

NOTE: **Note:**
When you remove a cluster, you only remove its relation to GitLab, not the
cluster itself. To remove the cluster, you can do so by visiting the GKE
dashboard or using `kubectl`.

To remove the Kubernetes cluster integration from your project, simply click on the
**Remove integration** button. You will then be able to follow the procedure
and add a Kubernetes cluster again.

## What you can get with the Kubernetes integration

Here's what you can do with GitLab if you enable the Kubernetes integration.

### Deploy Boards

> Available in [GitLab Premium][ee].

GitLab's Deploy Boards offer a consolidated view of the current health and
status of each CI [environment](../../../ci/environments.md) running on Kubernetes,
displaying the status of the pods in the deployment. Developers and other
teammates can view the progress and status of a rollout, pod by pod, in the
workflow they already use without any need to access Kubernetes.

[> Read more about Deploy Boards](https://docs.gitlab.com/ee/user/project/deploy_boards.html)

### Canary Deployments

> Available in [GitLab Premium][ee].

Leverage [Kubernetes' Canary deployments](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#canary-deployments)
and visualize your canary deployments right inside the Deploy Board, without
the need to leave GitLab.

[> Read more about Canary Deployments](https://docs.gitlab.com/ee/user/project/canary_deployments.html)

### Kubernetes monitoring

Automatically detect and monitor Kubernetes metrics. Automatic monitoring of
[NGINX ingress](../integrations/prometheus_library/nginx.md) is also supported.

[> Read more about Kubernetes monitoring](../integrations/prometheus_library/kubernetes.md)

### Auto DevOps

Auto DevOps automatically detects, builds, tests, deploys, and monitors your
applications.

To make full use of Auto DevOps(Auto Deploy, Auto Review Apps, and Auto Monitoring)
you will need the Kubernetes project integration enabled.

[> Read more about Auto DevOps](../../../topics/autodevops/index.md)

### Web terminals

NOTE: **Note:**
Introduced in GitLab 8.15. You must be the project owner or have `maintainer` permissions
to use terminals. Support is limited to the first container in the
first pod of your environment.

When enabled, the Kubernetes service adds [web terminal](../../../ci/environments.md#web-terminals)
support to your [environments](../../../ci/environments.md). This is based on the `exec` functionality found in
Docker and Kubernetes, so you get a new shell session within your existing
containers. To use this integration, you should deploy to Kubernetes using
the deployment variables above, ensuring any pods you create are labelled with
`app=$CI_ENVIRONMENT_SLUG`. GitLab will do the rest!

## Read more

- [Connecting and deploying to an Amazon EKS cluster](eks_and_gitlab/index.md)

[permissions]: ../../permissions.md
[ee]: https://about.gitlab.com/pricing/
[Auto DevOps]: ../../../topics/autodevops/index.md
