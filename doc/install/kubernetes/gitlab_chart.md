# GitLab Helm Chart
> **Note:** The chart is currently **beta**, if you encounter any problems please [open an issue](https://gitlab.com/charts/gitlab/issues/new).

For more information on available GitLab Helm Charts, please see our [overview](index.md#chart-overview).

## Introduction

The `gitlab` chart is the best way to operate GitLab on Kubernetes. This chart contains all the required components to get started, and can scale to large deployments.

The default deployment includes:

- Core GitLab components: Unicorn, Shell, Workhorse, Registry, Sidekiq, and Gitaly
- Optional dependencies: Postgres, Redis, Minio
- An auto-scaling, unprivileged [GitLab Runner](https://docs.gitlab.com/runner/) using the Kubernetes executor
- Automatically provisioned SSL via [Let's Encrypt](https://letsencrypt.org/).

### Limitations

Some features and functions are not currently available in the beta release.
For details, see [known issues and limitations](https://gitlab.com/charts/gitlab/blob/master/doc/architecture/beta.md#known-issues-and-limitations) in the charts repository.

## Prerequisites

In order to deploy GitLab on Kubernetes, a few prerequisites are required.

1. `helm` and `kubectl` [installed on your computer](preparation/tools_installation.md).
1. A Kubernetes cluster, version 1.8 or higher. 6vCPU and 16GB of RAM is recommended.
  * [Google GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-container-cluster)
  * [Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)
  * [Microsoft AKS](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough-portal)
1. A [wildcard DNS entry and external IP address](preparation/networking.md)
1. [Authenticate and connect](preparation/connect.md) to the cluster
1. Configure and initialize [Helm Tiller](preparation/tiller.md).

## Configuring and Installing GitLab

> **Note**: For deployments to Amazon EKS, there are [additional configuration requirements](preparation/eks.md).

For simple deployments, running all services within Kubernetes, only three parameters are required:
- `global.hosts.domain`: the [base domain](preparation/networking.md) of the wildcard host entry. For example, `mycompany.io` if the wild card entry is `*.mycompany.io`.
- `global.hosts.externalIP`: the [external IP](preparation/networking.md) which the wildcard DNS resolves to.
- `certmanager-issuer.email`: Email address to use when requesting new SSL certificates from Let's Encrypt.

For enterprise deployments, or to utilize advanced settings, please use the instructions in the [`gitlab` chart project](https://gitlab.com/charts/gitlab) for the most up to date directions.
- [External Postgres, Redis, and other dependencies](https://gitlab.com/charts/gitlab/tree/master/doc/advanced)
- [Persistence settings](https://gitlab.com/charts/gitlab/blob/master/doc/installation/storage.md)
- [Manual TLS certificates](https://gitlab.com/charts/gitlab/blob/master/doc/installation/tls.md)
- [Manual secret creation](https://gitlab.com/charts/gitlab/blob/master/doc/installation/secrets.md)

For additional configuration options, consult the [full list of settings](https://gitlab.com/charts/gitlab/blob/master/doc/installation/command-line-options.md).

## Installing GitLab using the Helm Chart

Once you have all of your configuration options collected, we can get any dependencies and
run helm. In this example, we've named our helm release "gitlab".

```
helm repo add gitlab https://charts.gitlab.io/
helm update
helm upgrade --install gitlab gitlab/gitlab \
  --timeout 600 \
  --set global.hosts.domain=example.local \
  --set global.hosts.externalIP=10.10.10.10 \
  --set certmanager-issuer.email=me@example.local
```

### Monitoring the Deployment

This will output the list of resources installed once the deployment finishes which may take 5-10 minutes.

The status of the deployment can be checked by running `helm status gitlab` which can also be done while
the deployment is taking place if you run the command in another terminal.

### Initial login

You can access the GitLab instance by visiting the domain name beginning with `gitlab.` followed by the domain specified during installation. From the example above, the URL would be `https://gitlab.example.local`.

If you manually created the secret for initial root password, you
can use that to sign in as `root` user. If not, Gitlab automatically
created a random password for `root` user. This can be extracted by the
following command (replace `<name>` by name of the release - which is `gitlab`
if you used the command above).

```
kubectl get secret <name>-gitlab-initial-root-password -ojsonpath={.data.password} | base64 --decode
```

## Outgoing email

By default outgoing email is disabled. To enable it, provide details for your SMTP server
using the `global.smtp` and `global.email` settings. You can find details for these settings in the
[command line options](https://gitlab.com/charts/gitlab/blob/master/doc/installation/command-line-options.md#email-configuration).

If your SMTP server requires authentication make sure to read the section on providing
your password in the [secrets documentation](https://gitlab.com/charts/gitlab/blob/master/doc/installation/secrets.md#smtp-password).
You can disable authentication settings with `--set global.smtp.authentication=""`.

If your Kubernetes cluster is on GKE, be aware that smtp [ports 25, 465, and 587
are blocked](https://cloud.google.com/compute/docs/tutorials/sending-mail/#using_standard_email_ports).

## Deploying the Community Edition

To deploy the Community Edition, include these options in your `helm install` command:

```shell
--set gitlab.migrations.image.repository=registry.gitlab.com/gitlab-org/build/cng/gitlab-rails-ce
--set gitlab.sidekiq.image.repository=registry.gitlab.com/gitlab-org/build/cng/gitlab-sidekiq-ce
--set gitlab.unicorn.image.repository=registry.gitlab.com/gitlab-org/build/cng/gitlab-unicorn-ce
```

## Updating GitLab using the Helm Chart

Once your GitLab Chart is installed, configuration changes and chart updates
should be done using `helm upgrade`:

```bash
helm upgrade -f values.yaml gitlab gitlab/gitlab
```

## Uninstalling GitLab using the Helm Chart

To uninstall the GitLab Chart, run the following:

```bash
helm delete gitlab
```

[kube-srv]: https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services---service-types
[storageclass]: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#storageclasses
