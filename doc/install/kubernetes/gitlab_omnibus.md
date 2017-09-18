# GitLab-Omnibus Helm Chart
> **Note:**
* This Helm chart is in beta, while [additional features](https://gitlab.com/charts/charts.gitlab.io/issues/68) are being worked on.
* GitLab is working on a [cloud native set of Charts](https://gitlab.com/charts/helm.gitlab.io/blob/master/README.md) which will eventually replace these.
* These charts have been tested on Google Container Engine and Azure Container Service. Other Kubernetes installations may work as well, if not please [open an issue](https://gitlab.com/charts/charts.gitlab.io/issues).

This work is based partially on: https://github.com/lwolf/kubernetes-gitlab/. GitLab would like to thank Sergey Nuzhdin for his work.

For more information on available GitLab Helm Charts, please see our [overview](index.md#chart-overview).

## Introduction

This chart provides an easy way to get started with GitLab, provisioning an installation with nearly all functionality enabled. SSL is automatically provisioned via [Let's Encrypt](https://letsencrypt.org/).

The deployment includes:

- A [GitLab Omnibus](https://docs.gitlab.com/omnibus/) Pod, including Mattermost, Container Registry, and Prometheus
- An auto-scaling [GitLab Runner](https://docs.gitlab.com/runner/) using the Kubernetes executor
- [Redis](https://github.com/kubernetes/charts/tree/master/stable/redis)
- [PostgreSQL](https://github.com/kubernetes/charts/tree/master/stable/postgresql)
- [NGINX Ingress](https://github.com/kubernetes/charts/tree/master/stable/nginx-ingress)
- Persistent Volume Claims for Data, Registry, Postgres, and Redis

### Limitations

* This chart is suited for small to medium size deployments, because [High Availability](https://docs.gitlab.com/ee/administration/high_availability/) and [Geo](https://docs.gitlab.com/ee/gitlab-geo/README.html) will not be supported.
* It is in beta. Additional features to support production deployments, like backups, are [in development](https://gitlab.com/charts/charts.gitlab.io/issues/68). Once completed, this chart will be generally available.
* A new generation of [cloud native charts](index.md#upcoming-cloud-native-helm-charts) is in development, and will eventually deprecate these. Due to the difficulty in supporting upgrades to the new architecture, migrating will require exporting data out of this instance and importing it into the new deployment. We do not expect these to be production ready before the second half of 2018.

For more information on available GitLab Helm Charts, please see our [overview](index.md#chart-overview).

## Prerequisites

- _At least_ 4 GB of RAM available on your cluster. 41GB of storage and 2 CPU are also required.
- Kubernetes 1.4+ with Beta APIs enabled
- [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) provisioner support in the underlying infrastructure
- A [wildcard DNS entry](#networking-prerequisites), which resolves to the external IP address
- The `kubectl` CLI installed locally and authenticated for the cluster
- The [Helm client](https://github.com/kubernetes/helm/blob/master/docs/quickstart.md) installed locally on your machine

### Networking Prerequisites

This chart configures a GitLab server and Kubernetes cluster which can support dynamic [Review Apps](https://docs.gitlab.com/ee/ci/review_apps/index.html), as well as services like the integrated [Container Registry](https://docs.gitlab.com/ee/user/project/container_registry.html) and [Mattermost](https://docs.gitlab.com/omnibus/gitlab-mattermost/).

To support the GitLab services and dynamic environments, a wildcard DNS entry is required which resolves to the [Load Balancer](#load-balancer-ip) or [External IP](#external-ip). Configuration of the DNS entry will depend upon the DNS service being used.

#### External IP (Recommended)

To provision an external IP on GCP and Azure, simply request a new address from the Networking section. Ensure that the region matches the region your container cluster is created in. Note, it is important that the IP is not assigned at this point in time. It will be automatically assigned once the Helm chart is installed, and assigned to the Load Balancer.

Now that an external IP address has been allocated, ensure that the wildcard DNS entry you would like to use resolves to this IP. Please consult the documentation for your DNS service for more information on creating DNS records.

Finally, set the `baseIP` setting to this IP address when [deploying GitLab](#configuring-and-installing-gitlab).

#### Load Balancer IP

If you do not specify a `baseIP`, an IP will be assigned to the Load Balancer or Ingress. You can retrieve this IP by running the following command *after* deploying GitLab:

`kubectl get svc -w --namespace nginx-ingress nginx`

The IP address will be displayed in the `EXTERNAL-IP` field, and should be used to configure the Wildcard DNS entry. For more information on creating a wildcard DNS entry, consult the documentation for the DNS server you are using.

For production deployments of GitLab, we strongly recommend using an [External IP](#external-ip).

## Configuring and Installing GitLab

For most installations, only two parameters are required:
- `baseDomain`: the [base domain](#networking-prerequisites) of the wildcard host entry. For example, `mycompany.io` if the wild card entry is `*.mycompany.io`.
- `legoEmail`: Email address to use when requesting new SSL certificates from Let's Encrypt.

Other common configuration options:
- `baseIP`: the desired [external IP address](#external-ip-recommended)
- `gitlab`: Choose the [desired edition](https://about.gitlab.com/products), either `ee` or `ce`. `ce` is the default.
- `gitlabEELicense`: For Enterprise Edition, the [license](https://docs.gitlab.com/ee/user/admin_area/license.html) can be installed directly via the Chart
- `provider`: Optimizes the deployment for a cloud provider. The default is `gke` for [Google Container Engine](https://cloud.google.com/container-engine/), with `acs` also supported for the [Azure Container Service](https://azure.microsoft.com/en-us/services/container-service/).

For additional configuration options, consult the [values.yaml](https://gitlab.com/charts/charts.gitlab.io/blob/master/charts/gitlab-omnibus/values.yaml).

### Choosing a different GitLab release version

The version of GitLab installed is based on the `gitlab` setting (see [section](#choosing-gitlab-edition) above), and
the value of the corresponding helm setting: `gitlabCEImage` or `gitabEEImage`.

```yaml
gitlab: CE
gitlabCEImage: gitlab/gitlab-ce:9.5.2-ce.0
gitlabEEImage: gitlab/gitlab-ee:9.5.2-ee.0
```

The different images can be found in the [gitlab-ce](https://hub.docker.com/r/gitlab/gitlab-ce/tags/) and [gitlab-ee](https://hub.docker.com/r/gitlab/gitlab-ee/tags/)
repositories on Docker Hub.

### Persistent storage
> **Note:**
If you are using a machine type with support for less than 4 attached disks, like an Azure trial, you should disable dedicated storage for Postgres and Redis.

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
> **Note:**
You may see a temporary error message `SchedulerPredicates failed due to PersistentVolumeClaim is not bound` while storage provisions. Once the storage provisions, the pods will automatically start. This may take a couple minutes depending on your cloud provider. If the error persists, please review the [prerequisites](#prerequisites) to ensure you have enough RAM, CPU, and storage.

Add the GitLab Helm repository and initialize Helm:

```bash
helm repo add gitlab https://charts.gitlab.io
helm init
```

Once you have reviewed the [configuration settings](#configuring-and-installing-gitlab) you can install the chart. We recommending saving your configuration options in a `values.yaml` file for easier upgrades in the future.

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
should we done using `helm upgrade`:

```bash
helm upgrade -f values.yaml gitlab gitlab/gitlab-omnibus
```

## Uninstalling GitLab using the Helm Chart

To uninstall the GitLab Chart, run the following:

```bash
helm delete gitlab
```

[kube-srv]: https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services---service-types
[storageclass]: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#storageclasses
