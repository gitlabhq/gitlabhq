# GitLab Helm Chart

The `gitlab` Helm chart installs GitLab into your Kubernetes cluster.

This chart includes the following:

- Deployment using the [gitlab-ce](https://hub.docker.com/r/gitlab/gitlab-ce) or [gitlab-ee](https://hub.docker.com/r/gitlab/gitlab-ee) container image
- ConfigMap containing the `gitlab.rb` contents that configure [GitLab Omnibus](https://docs.gitlab.com/omnibus/settings/configuration.html#configuration-options)
- Persistent Volume Claims for Data, Config, Logs, and Registry Storage
- Service
- Optional Redis Deployment using the [Redis Chart](https://github.com/kubernetes/charts/tree/master/stable/redis) (defaults to enabled)
- Optional PostgreSQL Deployment using the [PostgreSQL Chart](https://github.com/kubernetes/charts/tree/master/stable/postgresql) (defaults to enabled)
- Optional Ingress (defaults to disabled)

## Installing

## Prerequisites

- _At least_ 3 GB of RAM available on your cluster, in chunks of 1 GB
- Kubernetes 1.4+ with Beta APIs enabled
- PV provisioner support in the underlying infrastructure
- The ability to point a DNS entry or URL at your GitLab install
- The Helm Server (Tiller) already installed and running in the cluster
- The KubeCtl CLI installed locally and authenticated for the cluster
- The Helm Client installed locally
- The GitLab Helm Repo added to your Helm Client [link]

## Installing

```bash
helm install --namepace <NAMEPACE> --name gitlab -f <CONFIG_VALUES_FILE> gitlab/gitlab
```

- `<NAMESPACE>` is the kubernetes namespace where you want to install GitLab
- `<CONFIG_VALUES_FILE>` is the path to values file containing your custom configuration. See [link] to create it.

## Configuration

Create a `values.yaml` file for your GitLab configuration. See [Helm docs](https://github.com/kubernetes/helm/blob/master/docs/chart_template_guide/values_files.md)
for information on how your values file will override the defaults.

The default configuration can always be found in the [values.yaml](https://gitlab.com/charts/charts.gitlab.io/blob/master/charts/gitlab/values.yaml) in the chart repository

### Required Configuration

In order for the install to work at all, your config file needs to specify the following:

 - An `externalUrl` that GitLab will be reachable at.
