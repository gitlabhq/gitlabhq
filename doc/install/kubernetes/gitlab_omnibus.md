# GitLab-Omnibus Helm Chart
> These Helm charts are in beta. GitLab is working on a [cloud-native](http://docs.gitlab.com/omnibus/package-information/cloud_native.html) set of [Charts](https://gitlab.com/charts/helm.gitlab.io) which will replace these.

> Officially supported cloud providers are Google Container Service and Azure Container Service.

This work is based partially on: https://github.com/lwolf/kubernetes-gitlab/. GitLab would like to thank Sergey Nuzhdin for his work.

## Introduction

This chart provides an easy way to get started with GitLab, provisioning an installation with nearly all functionality enabled. SSL is automatically provisioned as well via [Let's Encrypt](https://letsencrypt.org/).

The deployment includes:

- A [GitLab Omnibus](https://docs.gitlab.com/omnibus/) Pod, including Mattermost, Container Registry, and Prometheus
- An auto-scaling [GitLab Runner](https://docs.gitlab.com/runner/) using the Kubernetes executor
- [Redis](https://github.com/kubernetes/charts/tree/master/stable/redis)
- [PostgreSQL](https://github.com/kubernetes/charts/tree/master/stable/postgresql)
- [NGINX Ingress](https://github.com/kubernetes/charts/tree/master/stable/nginx-ingress)
- Persistent Volume Claims for Data, Registry, Postgres, and Redis

A video demonstration of GitLab utilizing this chart [is available](https://about.gitlab.com/handbook/sales/demo/).

Terms:

-  Google Cloud Platform (**GCP**)
-  Google Container Engine (**GKE**)
-  Azure Container Service (**ACS**)
-  Kubernetes (**k8s**)

## Prerequisites

- _At least_ 4 GB of RAM available on your cluster, in chunks of 1 GB. 41GB of storage and 2 CPU are also required.
- Kubernetes 1.4+ with Beta APIs enabled
- [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) provisioner support in the underlying infrastructure
- An [external IP address](#networking-prerequisites)
- A [wildcard DNS entry](#networking-prerequisites), which resolves to the external IP address
- The `kubectl` CLI installed locally and authenticated for the cluster
- The Helm Client installed locally
- The Helm Server (Tiller) already installed and running in the cluster, by running `helm init`
- The GitLab Helm Repo [added to your Helm Client](index.md#add-the-gitlab-helm-repository)

### Networking Prerequisites

This chart configures a GitLab server and Kubernetes cluster which can support dynamic [Review Apps](https://docs.gitlab.com/ee/ci/review_apps/index.html), as well as services like the integrated [Container Registry](https://docs.gitlab.com/ee/user/project/container_registry.html) and [Mattermost](https://docs.gitlab.com/omnibus/gitlab-mattermost/).

To support the GitLab services and dynamic environments, a wildcard DNS entry is required which resolves to the external Load Balancer IP.

To provision an external IP on GCP and Azure, simply request a new address from the Networking section. Ensure that the region matches the region your container cluster is created in. Note, it is important that the IP is not assigned at this point in time. It will be automatically assigned once the Helm chart is installed, and assigned to the Load Balancer.

Now that an external IP address has been allocated, ensure that the wildcard DNS entry you would like to use resolves to this IP. Please consult the documentation for your DNS service for more information on creating DNS records.

## Configuring and Installing GitLab

For most installations, only two parameters are required:
- `baseIP`: the desired [external IP address](#networking-prerequisites)
- `baseDomain`: the [base domain](#networking-prerequisites) with the wildcard host entry resolving to the `baseIP`. For example, `mycompany.io`.

Other common configuration options:
- `gitlab`: Choose the [desired edition](https://about.gitlab.com/products), either `ee` or `ce`. `ce` is the default.
- `gitlabEELicense`: For Enterprise Edition, the [license](https://docs.gitlab.com/ee/user/admin_area/license.html) can be installed directly via the Chart
- `provider`: Optimizes the deployment for a cloud provider. The default is `gke` for GCP, with `acs` also supported for Azure.
- `legoEmail`: Email address to use when requesting new SSL certificates from Let's Encrypt

For additional configuration options, consult the [values.yaml](https://gitlab.com/charts/charts.gitlab.io/blob/master/charts/gitlab-omnibus/values.yaml).

These settings can either be passed directly on the command line:
```bash
helm install --name gitlab --set baseDomain=gitlab.io,baseIP=1.1.1.1,gitlab=ee,gitlabEELicense=$LICENSE,legoEmail=email@gitlab.com gitlab/gitlab-omnibus
```

or within a YAML file:
```bash
helm install --name gitlab -f values.yaml gitlab/gitlab-omnibus
```

> **Note:**
If you are using a machine type with support for less than 4 attached disks, like an Azure trial, you should disable dedicated storage for [Postgres and Redis](#persistent-storage).

### Choosing a different GitLab release version

The version of GitLab installed is based on the `gitlab` setting (see [section](#choosing-gitlab-edition) above), and
the value of the corresponding helm setting: `gitlabCEImage` or `gitabEEImage`.

```yaml
gitlab: CE
gitlabCEImage: gitlab/gitlab-ce:9.1.2-ce.0
gitlabEEImage: gitlab/gitlab-ee:9.1.2-ee.0
```

The different images can be found in the [gitlab-ce](https://hub.docker.com/r/gitlab/gitlab-ce/tags/) and [gitlab-ee](https://hub.docker.com/r/gitlab/gitlab-ee/tags/)
repositories on Docker Hub.

> **Note:**
There is no guarantee that other release versions of GitLab, other than what are
used by default in the chart, will be supported by a chart install.

### Persistent storage

By default, persistent storage is enabled for GitLab and the charts it depends
on (Redis and PostgreSQL).

Components can have their claim size set from your `values.yaml`, along with whether to provision separate storage for Postgres and Redis.

Basic configuration:

```yaml
redisImage: redis:3.2.10
redisDedicatedStorage: true
redisStorageSize: 5Gi
postgresImage: postgres:9.6.3
# If you disable postgresDedicatedStorage, you should consider bumping up gitlabRailsStorageSize
postgresDedicatedStorage: true
postgresStorageSize: 30Gi
gitlabRailsStorageSize: 30Gi
gitlabRegistryStorageSize: 30Gi
gitlabConfigStorageSize: 1Gi
```

### Routing and SSL

Ingress routing and SSL are automatically configured within this Chart. An NGINX ingress is provisioned and configured, and will route traffic to any service. SSL certificates are automatically created and configured by [kube-lego](https://github.com/kubernetes/charts/tree/master/stable/kube-lego).

> **Note:**
Let's Encrypt limits a single TLD to five certificate requests within a single week. This means that common DNS wildcard services like [xip.io](http://xip.io) and [nip.io](http://nip.io) are unlikely to work.

## Installing GitLab using the Helm Chart
> You may see a temporary error message `SchedulerPredicates failed due to PersistentVolumeClaim is not bound` while storage provisions. Once the storage provisions, the pods will automatically restart. This may take a couple minutes depending on your cloud provider. If the error persists, please review the [prerequisites](#prerequisites) to ensure you have enough RAM, CPU, and storage.

Once you have reviewed the [configuration settings](#configuring-and-installing-gitlab) and [added the Helm repository](index.md#add-the-gitlab-helm-repository), you can install the chart. We recommending saving your configuration options in a `values.yaml` file for easier upgrades in the future.

For example:
```bash
helm install --name gitlab -f values.yaml gitlab/gitlab-omnibus
```

or passing them on the command line:
```bash
helm install --name gitlab --set baseDomain=gitlab.io,baseIP=1.1.1.1,gitlab=ee,gitlabEELicense=$LICENSE,legoEmail=email@gitlab.com gitlab/gitlab-omnibus
```

## Updating GitLab using the Helm Chart

Once your GitLab Chart is installed, configuration changes and chart updates
should we done using `helm upgrade`

```bash
helm upgrade -f <CONFIG_VALUES_FILE> <RELEASE-NAME> gitlab/gitlab
```

where:

- `<CONFIG_VALUES_FILE>` is the path to values file containing your custom
  [configuration] (#configuring-and-installing-gitlab).
- `<RELEASE-NAME>` is the name you gave the chart when installing it.
  In the [Install section](#installing-gitlab-using-the-helm-chart) we called it `gitlab`.

## Uninstalling GitLab using the Helm Chart

To uninstall the GitLab Chart, run the following:

```bash
helm delete <RELEASE-NAME>
```

where:

- `<RELEASE-NAME>` is the name you gave the chart when installing it.
  In the [Install section](#installing) we called it `gitlab`.

[kube-srv]: https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services---service-types
[storageclass]: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#storageclasses
