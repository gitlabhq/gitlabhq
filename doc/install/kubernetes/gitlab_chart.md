# GitLab Helm Chart
> **Note:**
* This chart has been tested on Google Kubernetes Engine and Azure Container Service.

**This chart is deprecated.** For small installations on Kubernetes today, we recommend the beta [`gitlab-omnibus` Helm chart](gitlab_omnibus.md).

A new [cloud native GitLab chart](index.md#cloud-native-gitlab-chart) is in development with increased scalability and resilience, among other benefits. The cloud native chart will replace both the `gitlab` and `gitlab-omnibus` charts when available later this year.

Due to the significant architectural changes, migrating will require backing up data out of this instance and restoring it into the new deployment. For more information on available GitLab Helm Charts, please see our [overview](index.md#chart-overview).

## Introduction

The `gitlab` Helm chart deploys just GitLab into your Kubernetes cluster, and offers extensive configuration options. This chart requires advanced knowledge of Kubernetes to successfully use. We **strongly recommend** the [gitlab-omnibus](gitlab_omnibus.md) chart.

This chart includes the following:

- Deployment using the [gitlab-ce](https://hub.docker.com/r/gitlab/gitlab-ce) or [gitlab-ee](https://hub.docker.com/r/gitlab/gitlab-ee) container image
- ConfigMap containing the `gitlab.rb` contents that configure [Omnibus GitLab](https://docs.gitlab.com/omnibus/settings/configuration.html#configuration-options)
- Persistent Volume Claims for Data, Config, Logs, and Registry Storage
- A Kubernetes service
- Optional Redis deployment using the [Redis Chart](https://github.com/kubernetes/charts/tree/master/stable/redis) (defaults to enabled)
- Optional PostgreSQL deployment using the [PostgreSQL Chart](https://github.com/kubernetes/charts/tree/master/stable/postgresql) (defaults to enabled)
- Optional Ingress (defaults to disabled)

## Prerequisites

- _At least_ 3 GB of RAM available on your cluster. 41GB of storage and 2 CPU are also required.
- Kubernetes 1.4+ with Beta APIs enabled
- [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) provisioner support in the underlying infrastructure
- The ability to point a DNS entry or URL at your GitLab install
- The `kubectl` CLI installed locally and authenticated for the cluster
- The [Helm client](https://github.com/kubernetes/helm/blob/master/docs/quickstart.md) installed locally on your machine

## Configuring GitLab

Create a `values.yaml` file for your GitLab configuration. See the
[Helm docs](https://github.com/kubernetes/helm/blob/master/docs/chart_template_guide/values_files.md)
for information on how your values file will override the defaults.

The default configuration can always be [found in the `values.yaml`](https://gitlab.com/charts/charts.gitlab.io/blob/master/charts/gitlab/values.yaml), in the chart repository.

### Required configuration

In order for GitLab to function, your config file **must** specify the following:

- An `externalUrl` that GitLab will be reachable at.

### Choosing GitLab Edition

The Helm chart defaults to installing GitLab CE. This can be controlled by setting the `edition` variable in your values.

Setting `edition` to GitLab Enterprise Edition (EE) in your `values.yaml`

```yaml
edition: EE

externalUrl: 'http://gitlab.example.com'
```

### Choosing a different GitLab release version

The version of GitLab installed is based on the `edition` setting (see [section](#choosing-gitlab-edition) above), and
the value of the corresponding helm setting: `ceImage` or `eeImage`.

```yaml
## GitLab Edition
## ref: https://about.gitlab.com/products/
## - CE - Community Edition
## - EE - Enterprise Edition - (requires license issued by GitLab Inc)
##
edition: CE

## GitLab CE image
## ref: https://hub.docker.com/r/gitlab/gitlab-ce/tags/
##
ceImage: gitlab/gitlab-ce:9.1.2-ce.0

## GitLab EE image
## ref: https://hub.docker.com/r/gitlab/gitlab-ee/tags/
##
eeImage: gitlab/gitlab-ee:9.1.2-ee.0
```

The different images can be found in the [gitlab-ce](https://hub.docker.com/r/gitlab/gitlab-ce/tags/) and [gitlab-ee](https://hub.docker.com/r/gitlab/gitlab-ee/tags/)
repositories on Docker Hub

> **Note:**
There is no guarantee that other release versions of GitLab, other than what are
used by default in the chart, will be supported by a chart install.


### Custom Omnibus GitLab configuration

In addition to the configuration options provided for GitLab in the Helm Chart, you can also pass any custom configuration
that is valid for the [Omnibus GitLab Configuration](https://docs.gitlab.com/omnibus/settings/configuration.html).

The setting to pass these values in is `omnibusConfigRuby`. It accepts any valid
Ruby code that could used in the Omnibus `/etc/gitlab/gitlab.rb` file. In
Kubernetes, the contents will be stored in a ConfigMap.

Example setting:

```yaml
omnibusConfigRuby: |
  unicorn['worker_processes'] = 2;
  gitlab_rails['trusted_proxies'] = ["10.0.0.0/8","172.16.0.0/12","192.168.0.0/16"];
```

### Persistent storage

By default, persistent storage is enabled for GitLab and the charts it depends
on (Redis and PostgreSQL).

Components can have their claim size set from your `values.yaml`, and each
component allows you to optionally configure the `storageClass` variable so you
can take advantage of faster drives on your cloud provider.

Basic configuration:

```yaml
## Enable persistence using Persistent Volume Claims
## ref: http://kubernetes.io/docs/user-guide/persistent-volumes/
## ref: https://docs.gitlab.com/ce/install/requirements.html#storage
##
persistence:
  ## This volume persists generated configuration files, keys, and certs.
  ##
  gitlabEtc:
    enabled: true
    size: 1Gi
    ## If defined, volume.beta.kubernetes.io/storage-class: <storageClass>
    ## Default: volume.alpha.kubernetes.io/storage-class: default
    ##
    # storageClass:
    accessMode: ReadWriteOnce
  ## This volume is used to store git data and other project files.
  ## ref: https://docs.gitlab.com/omnibus/settings/configuration.html#storing-git-data-in-an-alternative-directory
  ##
  gitlabData:
    enabled: true
    size: 10Gi
    ## If defined, volume.beta.kubernetes.io/storage-class: <storageClass>
    ## Default: volume.alpha.kubernetes.io/storage-class: default
    ##
    # storageClass:
    accessMode: ReadWriteOnce
  gitlabRegistry:
    enabled: true
    size: 10Gi
    ## If defined, volume.beta.kubernetes.io/storage-class: <storageClass>
    ## Default: volume.alpha.kubernetes.io/storage-class: default
    ##
    # storageClass:

  postgresql:
    persistence:
      # storageClass:
      size: 10Gi
  ## Configuration values for the Redis dependency.
  ## ref: https://github.com/kubernetes/charts/blob/master/stable/redis/README.md
  ##
  redis:
    persistence:
      # storageClass:
      size: 10Gi
```

>**Note:**
You can make use of faster SSD drives by adding a [StorageClass] to your cluster
and using the `storageClass` setting in the above config to the name of
your new storage class.

### Routing

By default, the GitLab chart uses a service type of `LoadBalancer` which will
result in the GitLab service being exposed externally using your cloud provider's
load balancer.

This field is configurable in your `values.yml` by setting the top-level
`serviceType` field. See the [Service documentation][kube-srv] for more
information on the possible values.

#### Ingress routing

Optionally, you can enable the Chart's ingress for use by an ingress controller
deployed in your cluster.

To enable the ingress, edit its section in your `values.yaml`:

```yaml
ingress:
  ## If true, gitlab Ingress will be created
  ##
  enabled: true

  ## gitlab Ingress hostnames
  ## Must be provided if Ingress is enabled
  ##
  hosts:
    - gitlab.example.com

  ## gitlab Ingress annotations
  ##
  annotations:
    kubernetes.io/ingress.class: nginx
```

You must also provide the list of hosts that the ingress will use. In order for
you ingress controller to work with the GitLab Ingress, you will need to specify
its class in an annotation.

>**Note:**
The Ingress alone doesn't expose GitLab externally. You need to have a Ingress controller setup to do that.
Setting up an Ingress controller can be done by installing the `nginx-ingress` helm chart. But be sure
to read the [documentation](https://github.com/kubernetes/charts/blob/master/stable/nginx-ingress/README.md).
>**Note:**
If you would like to use the Registry, you will also need to ensure your Ingress supports a [sufficiently large request size](http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size).

#### Preserving Source IPs

If you are using the `LoadBalancer` serviceType you may run into issues where user IP addresses in the GitLab
logs, and used in abuse throttling are not accurate. This is due to how Kubernetes uses source NATing on cluster nodes without endpoints.

See the [Kubernetes documentation](https://kubernetes.io/docs/tutorials/services/source-ip/#source-ip-for-services-with-typeloadbalancer) for more information.

To fix this you can add the following service annotation to your `values.yaml`

```yaml
## For minikube, set this to NodePort, elsewhere use LoadBalancer
## ref: http://kubernetes.io/docs/user-guide/services/#publishing-services---service-types
##
serviceType: LoadBalancer

## Optional annotations for gitlab service.
serviceAnnotations:
  service.beta.kubernetes.io/external-traffic: "OnlyLocal"
```

>**Note:**
If you are using the ingress routing, you will likely also need to specify the annotation on the service for the ingress
controller. For `nginx-ingress` you can check the
[configuration documentation](https://github.com/kubernetes/charts/blob/master/stable/nginx-ingress/README.md#configuration)
on how to add the annotation to the  `controller.service.annotations` array.

>**Note:**
When using the `nginx-ingress` controller on Google Kubernetes Engine (GKE), and using the `external-traffic` annotation,
you will need to additionally set the `controller.kind` to be DaemonSet. Otherwise only pods running on the same node
as the nginx controller will be able to reach GitLab. This may result in pods within your cluster not being able to reach GitLab.
See the [Kubernetes documentation](https://kubernetes.io/docs/tutorials/services/source-ip/#source-ip-for-services-with-typeloadbalancer) and
[nginx-ingress configuration documentation](https://github.com/kubernetes/charts/blob/master/stable/nginx-ingress/README.md#configuration)
for more information.

### External database

You can configure the GitLab Helm chart to connect to an external PostgreSQL
database.

>**Note:**
This is currently our recommended approach for a Production setup.

To use an external database, in your `values.yaml`, disable the included
PostgreSQL dependency, then configure access to your database:

```yaml
dbHost: "<reachable postgres hostname>"
dbPassword: "<password for the user with access to the db>"
dbUsername: "<user with read/write access to the database>"
dbDatabase: "<database name on postgres to connect to for GitLab>"

postgresql:
  # Sets whether the PostgreSQL helm chart is used as a dependency
  enabled: false
```

Be sure to check the GitLab documentation on how to
[configure the external database](../requirements.md#postgresql-requirements)

You can also configure the chart to use an external Redis server, but this is
not required for basic production use:

```yaml
dbHost: "<reachable redis hostname>"
dbPassword: "<password>"

redis:
  # Sets whether the Redis helm chart is used as a dependency
  enabled: false
```

### Sending email

By default, the GitLab container will not be able to send email from your cluster.
In order to send email, you should configure SMTP settings in the
`omnibusConfigRuby` section, as per the [GitLab Omnibus documentation](https://docs.gitlab.com/omnibus/settings/smtp.html).

>**Note:**
Some cloud providers restrict emails being sent out on SMTP, so you will have
to use a SMTP service that is supported by your provider. See this
[Google Cloud Platform page](https://cloud.google.com/compute/docs/tutorials/sending-mail/)
as and example.

Here is an example configuration for Mailgun SMTP support:

```yaml
omnibusConfigRuby: |
  # This is example config of what you may already have in your omnibusConfigRuby object
  unicorn['worker_processes'] = 2;
  gitlab_rails['trusted_proxies'] = ["10.0.0.0/8","172.16.0.0/12","192.168.0.0/16"];

  # SMTP settings
  gitlab_rails['smtp_enable'] = true
  gitlab_rails['smtp_address'] = "smtp.mailgun.org"
  gitlab_rails['smtp_port'] = 2525 # High port needed for Google Cloud
  gitlab_rails['smtp_authentication'] = "plain"
  gitlab_rails['smtp_enable_starttls_auto'] = false
  gitlab_rails['smtp_user_name'] = "postmaster@mg.your-mail-domain"
  gitlab_rails['smtp_password'] = "you-password"
  gitlab_rails['smtp_domain'] = "mg.your-mail-domain"
```

### HTTPS configuration

To setup HTTPS access to your GitLab server, first you need to configure the
chart to use the [ingress](#ingress-routing).

GitLab's config should be updated to support [proxied SSL](https://docs.gitlab.com/omnibus/settings/nginx.html#supporting-proxied-ssl).

In addition to having a Ingress Controller deployed and the basic ingress
settings configured, you will also need to specify in the ingress settings
which hosts to use HTTPS for.

Make sure `externalUrl` now includes `https://` instead of `http://` in its
value, and update the `omnibusConfigRuby` section:

```yaml
externalUrl: 'https://gitlab.example.com'

omnibusConfigRuby: |
  # This is example config of what you may already have in your omnibusConfigRuby object
  unicorn['worker_processes'] = 2;
  gitlab_rails['trusted_proxies'] = ["10.0.0.0/8","172.16.0.0/12","192.168.0.0/16"];

  # These are the settings needed to support proxied SSL
  nginx['listen_port'] = 80
  nginx['listen_https'] = false
  nginx['proxy_set_headers'] = {
    "X-Forwarded-Proto" => "https",
    "X-Forwarded-Ssl" => "on"
  }

ingress:
  enabled: true
  annotations:
   kubernetes.io/ingress.class: nginx
   # kubernetes.io/tls-acme: 'true' Annotation used for letsencrypt support

  hosts:
    - gitlab.example.com

    ## gitlab Ingress TLS configuration
    ## Secrets must be created in the namespace, and is not done for you in this chart
    ##
    tls:
      - secretName: gitlab-tls
        hosts:
          - gitlab.example.com
```

You will need to create the named secret in your cluster, specifying the private
and public certificate pair using the format outlined in the
[ingress documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls).

Alternatively, you can use the `kubernetes.io/tls-acme` annotation, and install
the `kube-lego` chart to your cluster to have Let's Encrypt issue your
certificate. See the [kube-lego documentation](https://github.com/kubernetes/charts/blob/master/stable/kube-lego/README.md)
for more information.

### Enabling the GitLab Container Registry

The GitLab Registry is disabled by default but can be enabled by providing an
external URL for it in the configuration. In order for the Registry to be easily
used by GitLab CI and your Kubernetes cluster, you will need to set it up with
a TLS certificate, so these examples will include the ingress settings for that
as well. See the [HTTPS Configuration section](#https-configuration)
for more explanation on some of these settings.

Example config:

```yaml
externalUrl: 'https://gitlab.example.com'

omnibusConfigRuby: |
  # This is example config of what you may already have in your omnibusConfigRuby object
  unicorn['worker_processes'] = 2;
  gitlab_rails['trusted_proxies'] = ["10.0.0.0/8","172.16.0.0/12","192.168.0.0/16"];

  registry_external_url 'https://registry.example.com';

  # These are the settings needed to support proxied SSL
  nginx['listen_port'] = 80
  nginx['listen_https'] = false
  nginx['proxy_set_headers'] = {
    "X-Forwarded-Proto" => "https",
    "X-Forwarded-Ssl" => "on"
  }
  registry_nginx['listen_port'] = 80
  registry_nginx['listen_https'] = false
  registry_nginx['proxy_set_headers'] = {
    "X-Forwarded-Proto" => "https",
    "X-Forwarded-Ssl" => "on"
  }

ingress:
  enabled: true
  annotations:
   kubernetes.io/ingress.class: nginx
   # kubernetes.io/tls-acme: 'true' Annotation used for letsencrypt support

  hosts:
    - gitlab.example.com
    - registry.example.com

    ## gitlab Ingress TLS configuration
    ## Secrets must be created in the namespace, and is not done for you in this chart
    ##
    tls:
      - secretName: gitlab-tls
        hosts:
          - gitlab.example.com
          - registry.example.com
```

## Installing GitLab using the Helm Chart
> You may see a temporary error message `SchedulerPredicates failed due to PersistentVolumeClaim is not bound` while storage provisions. Once the storage provisions, the pods will automatically restart. This may take a couple minutes depending on your cloud provider. If the error persists, please review the [prerequisites](#prerequisites) to ensure you have enough RAM, CPU, and storage.

Add the GitLab Helm repository and initialize Helm:

```bash
helm repo add gitlab https://charts.gitlab.io
helm init
```

Once you [have configured](#configuration) GitLab in your `values.yml` file,
run the following:

```bash
helm install --namespace <NAMESPACE> --name gitlab -f <CONFIG_VALUES_FILE> gitlab/gitlab
```

where:

- `<NAMESPACE>` is the Kubernetes namespace where you want to install GitLab.
- `<CONFIG_VALUES_FILE>` is the path to values file containing your custom
  configuration. See the [Configuration](#configuration) section to create it.

## Updating GitLab using the Helm Chart

Once your GitLab Chart is installed, configuration changes and chart updates
should we done using `helm upgrade`

```bash
helm upgrade --namespace <NAMESPACE> -f <CONFIG_VALUES_FILE> <RELEASE-NAME> gitlab/gitlab
```

where:

- `<NAMESPACE>` is the Kubernetes namespace where GitLab is installed.
- `<CONFIG_VALUES_FILE>` is the path to values file containing your custom
  [configuration] (#configuration).
- `<RELEASE-NAME>` is the name you gave the chart when installing it.
  In the [Install section](#installing) we called it `gitlab`.

## Uninstalling GitLab using the Helm Chart

To uninstall the GitLab Chart, run the following:

```bash
helm delete --namespace <NAMESPACE> <RELEASE-NAME>
```

where:

- `<NAMESPACE>` is the Kubernetes namespace where GitLab is installed.
- `<RELEASE-NAME>` is the name you gave the chart when installing it.
  In the [Install section](#installing) we called it `gitlab`.

[kube-srv]: https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services---service-types
[storageclass]: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#storageclasses
