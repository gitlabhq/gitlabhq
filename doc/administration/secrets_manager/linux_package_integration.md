---
stage: Sec
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Install OpenBao for a Linux package deployment of GitLab
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/9669) in GitLab 19.0 as an experiment.

{{< /history >}}

> [!warning]
> This feature is an [experiment](../../policy/development_stages_support.md#experiment)
> and subject to change without notice.
> This feature is not ready for public testing or production use.

Use a Kubernetes cluster to run OpenBao alongside a GitLab instance installed
with the Linux package. OpenBao runs in the cluster and connects to a PostgreSQL
database. GitLab Rails and Sidekiq connect to OpenBao over HTTPS.

Run OpenBao in one of two ways:

- **Colocated cluster**: A local Kubernetes distribution (for example, k3s) runs on the same host
  as your Linux package instance. Linux package-bundled NGINX acts as the TLS-terminating reverse proxy
  for the OpenBao external URL. The GitLab application connects to OpenBao through the endpoint
  that Kubernetes exposes on the shared network.
- **External Kubernetes cluster**: OpenBao runs in a separate Kubernetes cluster. You design the
  cluster Ingress and TLS termination. GitLab Rails and Sidekiq connect to the OpenBao URL you
  expose. Consider this approach if you have a multi-node Linux package deployment or if you prefer
  to use a managed Kubernetes service from your cloud provider.

> [!note]
> The Linux package-managed [PostgreSQL cluster](../postgresql/replication_and_failover.md) is not supported as the OpenBao database backend.
> If you use such cluster for GitLab, provision a separate PostgreSQL instance for OpenBao,
> either self-managed or as a managed cloud database service.
> For more information, see [issue 7292](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/7292).

## Prerequisites

{{< tabs >}}

{{< tab title="Colocated cluster" >}}

- GitLab 19.0 or later installed with the Linux package, with administrator access.
- A local Kubernetes distribution installed on the same host.
- `helm` and `kubectl` available on the host.
- A DNS record that points the OpenBao domain to the host's public IP address.

{{< /tab >}}

{{< tab title="External cluster" >}}

- A GitLab instance installed with the Linux package, with administrator access.
- An external Kubernetes cluster accessible from your Linux package instance nodes.
- `helm` and `kubectl` configured to access the cluster.
- A DNS record that points the OpenBao domain to the cluster Ingress IP address.

{{< /tab >}}

{{< /tabs >}}

## Requirements

{{< tabs >}}

{{< tab title="Colocated cluster" >}}

Before you install OpenBao, verify your Kubernetes distribution meets these requirements:

- [OpenBao sizing recommendations](_index.md#sizing-recommendations) must be satisfied in addition to
  the requirements of a Linux package instance and the requirements of your Kubernetes cluster.
- Nothing in your colocated Kubernetes should try to attach to ports already used by GitLab.
  Many small Kubernetes distributions install load balancers that bind to ports 80 and 443 by
  default. Disable such components because Linux package-managed NGINX is already listening on those ports.
- Your colocated Kubernetes must share a network with your Linux package instance so that Linux
  package-managed NGINX can route external OpenBao traffic to the OpenBao service and listen to requests
  from it. Your Linux package instance does not care whether the service is exposed through a Kubernetes
  `LoadBalancer` or `NodePort`, as long as both are reachable within the shared network.

{{< /tab >}}

{{< tab title="External cluster" >}}

Before you install OpenBao, verify your setup meets these requirements:

- [OpenBao sizing recommendations](_index.md#sizing-recommendations) must be satisfied by your
  Kubernetes cluster.
- Network connectivity must exist between OpenBao pods in the cluster and your Linux package
  instance nodes. How you establish this connectivity depends on your infrastructure. For example,
  you might use VPC peering, shared VPC, or firewall rules. GitLab Rails and Sidekiq must be able
  to reach the OpenBao URL you expose from the cluster.
- If you use Linux package-managed PostgreSQL as the OpenBao database, the PostgreSQL node must accept
  TCP connections from the cluster pod CIDR. Configure firewall or security group rules to allow
  this traffic on the database port.

{{< /tab >}}

{{< /tabs >}}

## Before you begin

{{< tabs >}}

{{< tab title="Colocated cluster" >}}

Before you begin:

1. Collect the CIDR of your Kubernetes CNI (pod network). You need it later to configure PostgreSQL
   authentication.
1. Collect the IP address of the network interface shared between your Linux package instance and
   Kubernetes (`<SHARED_NETWORK_IP>`). You need it later for several configuration values.
1. Confirm that your Kubernetes distribution is fully running before you attempt to install OpenBao.
1. Confirm that your `kubectl` context is set to this cluster (`KUBECONFIG` is configured correctly).

{{< /tab >}}

{{< tab title="External cluster" >}}

Before you begin:

1. Collect the CIDR of your Kubernetes pod network. You need it later to configure PostgreSQL
   authentication.
1. Collect the address of the PostgreSQL instance that OpenBao uses (`<POSTGRES_ADDRESS>`).
   This is either the IP address of your Linux package PostgreSQL node, or the endpoint of your
   external or managed PostgreSQL instance.
1. Confirm that your Kubernetes cluster is fully running before you attempt to install OpenBao.
1. Confirm that your `kubectl` context is set to this cluster (`KUBECONFIG` is configured correctly).

{{< /tab >}}

{{< /tabs >}}

## Provision the OpenBao PostgreSQL database

> [!note]
> `gitlab-psql` is only available when using the Linux package-managed PostgreSQL.
> If you use an external or managed PostgreSQL instance instead, run equivalent SQL commands on that instance. The user and database creation logic is the same.

`gitlab-psql` connects over the Unix socket and does not require TCP listeners,
so you can run these commands before `gitlab-ctl reconfigure`.

To provision the OpenBao PostgreSQL database:

1. Choose a strong password for the OpenBao database user. You use this same password
   in the Kubernetes secret in the last step of this section.

1. Create the OpenBao database user:

   ```shell
   sudo gitlab-psql \
     -c "CREATE USER openbao WITH PASSWORD '<strong-password>';"
   ```

1. Create the OpenBao database:

   ```shell
   sudo gitlab-psql \
     -c "CREATE DATABASE openbao OWNER openbao;"
   ```

1. Create the Kubernetes namespace and the secret that passes the database password
   to the Helm chart:

   ```shell
   kubectl create namespace openbao

   kubectl create secret generic openbao-db-secret \
     --namespace openbao \
     --from-literal=password='<strong-password>'
   ```

## Install OpenBao by using Helm

{{< tabs >}}

{{< tab title="Colocated cluster" >}}

To install OpenBao by using Helm:

1. Add the GitLab Helm repository:

   ```shell
   helm repo add gitlab https://charts.gitlab.io
   helm repo update
   ```

1. Create an `openbao-values.yaml` file with the following content, replacing the
   placeholder values with your actual domains and IP address:

   ```yaml
   config:
     ui: false
     storage:
       postgresql:
         haEnabled: true
         connection:
           host: "<SHARED_NETWORK_IP>"
           port: 5432
           database: openbao
           username: openbao
           sslMode: "disable"
           password:
             secret: openbao-db-secret
             key: password
     initialize:
       enabled: true
       oidcDiscoveryUrl: "https://<GITLAB_DOMAIN>"
       boundIssuer: "https://<GITLAB_DOMAIN>"
       boundAudiences: '"https://<OPENBAO_DOMAIN>"'

   gatewayRoute:
     enabled: false
   ```

1. Install OpenBao:

   ```shell
   helm upgrade --install openbao gitlab/openbao \
     --namespace openbao \
     --values openbao-values.yaml
   ```

   Do not use `--wait`, because the pod cannot connect to PostgreSQL.
   PostgreSQL only accepts TCP connections from the pod network
   after `gitlab-ctl reconfigure`. For now, pods are in a `CrashLoopBackOff`
   state.

   For all available chart options, see the
   [OpenBao Helm chart documentation](https://docs.gitlab.com/charts/charts/openbao/).

1. Define the internal URL to use for the OpenBao service. You have multiple options:

   - Load balancer. If using an internal load balancer on your colocated Kubernetes cluster, you can
     set the `oak['components']['openbao']['internal_url']` setting of your `gitlab.rb` file to the
     internal URL of your load balancer to route the requests to the OpenBao Kubernetes service. In this
     case, you must configure DNS to make sure the internal URL gets resolved to the internal load balancer IP.
   - Cluster `nodePort`. If you customize your OpenBao chart service to run on a Kubernetes service type
     `nodePort`, the internal URL can also be configured to that.
   - Service `clusterIP`. This option is likely the simplest. You can also skip a load balancer completely for your
     colocated cluster by informing the OpenBao internal URL to talk directly to the OpenBao service `clusterIP`.
     This option saves you from having to install one more load balancer in your machine because the Linux
     package-managed NGINX is already there.

   You can find the OpenBao service's `clusterIP` by running:

   ```shell
   kubectl -n openbao get svc openbao-active \
     -o jsonpath='{.spec.clusterIP}'
   ```

   Remember that the IP of the internal URL must be accessible by the host machine outside of your Kubernetes cluster.
   Configure your cluster to allocate IPs from your chosen `<SHARED_NETWORK_IP>`.

{{< /tab >}}

{{< tab title="External cluster" >}}

To install OpenBao by using Helm:

1. Add the GitLab Helm repository:

   ```shell
   helm repo add gitlab https://charts.gitlab.io
   helm repo update
   ```

1. Create an `openbao-values.yaml` file with the following content, replacing the
   placeholder values with your actual domains and PostgreSQL address:

   ```yaml
   config:
     ui: false
     storage:
       postgresql:
         haEnabled: true
         connection:
           host: "<POSTGRES_ADDRESS>"
           port: 5432
           database: openbao
           username: openbao
           password:
             secret: openbao-db-secret
             key: password
     initialize:
       enabled: true
       oidcDiscoveryUrl: "https://<GITLAB_DOMAIN>"
       boundIssuer: "https://<GITLAB_DOMAIN>"
       boundAudiences: '"https://<OPENBAO_DOMAIN>"'

   # The chart deploys a Kubernetes Ingress resource by default, which you need to provide the hostname to be reachable for GitLab Rails and Sidekiq
   # Alternatively, you could configure it to deploy an HTTPRoute resource, if you prefer to deploy a Gateway API controller.
   # 
   # For available network ingress and TLS configuration options, see:
   # https://docs.gitlab.com/charts/charts/openbao/#ingress-and-tls-configuration-options
   ingress:
     enabled: true
     hostname: "<OPENBAO_DOMAIN>"
   ```

1. Install OpenBao:

   ```shell
   helm upgrade --install openbao gitlab/openbao \
     --namespace openbao \
     --values openbao-values.yaml
   ```

For all available chart options, see the
[OpenBao Helm chart documentation](https://docs.gitlab.com/charts/charts/openbao/).

{{< /tab >}}

{{< /tabs >}}

## Configure GitLab

{{< tabs >}}

{{< tab title="Colocated cluster" >}}

Add the following to `/etc/gitlab/gitlab.rb` on your GitLab host, replacing the placeholder values
with your actual IP addresses and domain:

```ruby
# PostgreSQL: accept TCP connections from Kubernetes pods.
# Use the shared network IP to restrict exposure to the shared network.
# Using '0.0.0.0' makes PostgreSQL listen on all interfaces, including public ones.
postgresql['listen_address'] = '<SHARED_NETWORK_IP>'

# Local connections (GitLab Rails and other services) continue without a password.
postgresql['trust_auth_cidr_addresses'] = %w[127.0.0.1/32 ::1/128]

# Kubernetes pods authenticate with a password.
# Replace 10.42.0.0/16 with the CIDR of your Kubernetes CNI (pod network).
postgresql['md5_auth_cidr_addresses'] = %w[10.42.0.0/16]

# OAK: OpenBao reverse proxy via GitLab NGINX.
oak['enable'] = true
oak['network_address'] = '<SHARED_NETWORK_IP>'

oak['components']['openbao']['enable'] = true

# Replace 'https://openbao.example.com' with the URL of the DNS record
# you configured for OpenBao, which resolves to your host's public IP address.
oak['components']['openbao']['external_url'] = 'https://openbao.example.com'

# Example of service clusterIP. Replace <CLUSTER_IP> with the IP taken
# from the previous step.
#
# A nodePort would look similar: specify the cluster node IP with the port
# you chose when you deployed OpenBao.
#
# If behind a load balancer: 'http://openbao-internal.example.com'
oak['components']['openbao']['internal_url'] = 'http://<CLUSTER_IP>:8200'

# The URL that the GitLab application uses to connect to OpenBao.
gitlab_rails['openbao'] = {
  'url' => 'https://openbao.example.com'
}
```

In this configuration:

- `postgresql['listen_address']` is the shared network IP. Connections from CIDRs not listed
  in `trust_auth_cidr_addresses` or `md5_auth_cidr_addresses` are rejected by PostgreSQL.
- `postgresql['trust_auth_cidr_addresses']` is a list of CIDR blocks (localhost only). Connections
  from these blocks don't require a password. These addresses are used by GitLab services.
- `postgresql['md5_auth_cidr_addresses']` is a list of CIDR blocks from the pod CIDR. Connections
  from these blocks require a password. These addresses are used by OpenBao pods.
  password authentication. Used by OpenBao pods.
- `oak['network_address']` is the shared network IP. Used by NGINX listen directives.
- `oak['components']['openbao']['internal_url']` is the URL used by the GitLab application
  to talk to OpenBao.
- `gitlab_rails['openbao']['url']` is the OpenBao URL used by the GitLab application.

If your GitLab `external_url` setting uses `https://`, Let's Encrypt is already enabled.
Setting the OpenBao `external_url` scheme to `https://` is sufficient. GitLab
automatically adds the OpenBao domain as a Subject Alternative Name (SAN) on the
existing Let's Encrypt certificate.

To use a custom certificate instead, add:

```ruby
oak['components']['openbao']['ssl_certificate']     = '/etc/gitlab/ssl/openbao.example.com.crt'
oak['components']['openbao']['ssl_certificate_key'] = '/etc/gitlab/ssl/openbao.example.com.key'
```

{{< /tab >}}

{{< tab title="External cluster" >}}

Add the following to `/etc/gitlab/gitlab.rb` on each GitLab application node, replacing the placeholder
values with your actual addresses and domain:

```ruby
# The URL GitLab Rails uses to connect to OpenBao.
gitlab_rails['openbao'] = {
  'url' => 'https://openbao.example.com'
}
```

If you have separate Sidekiq nodes, add the same `gitlab_rails['openbao']` setting to
`/etc/gitlab/gitlab.rb` on each Sidekiq node. Sidekiq workers that provision secrets also
require access to OpenBao.

If you use the Linux package-managed PostgreSQL as the OpenBao database, also add the following to
`/etc/gitlab/gitlab.rb` on the PostgreSQL node:

```ruby
# PostgreSQL: accept TCP connections from Kubernetes pods.
postgresql['listen_address'] = '<POSTGRES_ADDRESS>'

# Local connections (GitLab Rails and other services) continue without a password.
postgresql['trust_auth_cidr_addresses'] = %w[127.0.0.1/32 ::1/128]

# Kubernetes pods authenticate with a password.
# Replace 10.0.0.0/14 with the CIDR of your Kubernetes pod network.
postgresql['md5_auth_cidr_addresses'] = %w[10.0.0.0/14]
```

{{< /tab >}}

{{< /tabs >}}

## Apply configuration changes

{{< tabs >}}

{{< tab title="Colocated cluster" >}}

Apply configuration changes:

```shell
sudo gitlab-ctl reconfigure
```

This command applies all configuration in a single pass:

- PostgreSQL starts accepting TCP connections from Kubernetes pods.
- NGINX is configured with the OpenBao virtual host, including TLS termination
  and HTTP to HTTPS redirect.
- The Let's Encrypt certificate is issued or renewed, if applicable.

{{< /tab >}}

{{< tab title="External cluster" >}}

Apply configuration changes on each node where you updated `gitlab.rb`:

```shell
sudo gitlab-ctl reconfigure
```

On the PostgreSQL node, this makes PostgreSQL accept TCP connections from the cluster pod network.
On Rails and Sidekiq nodes, this applies the OpenBao URL configuration.

{{< /tab >}}

{{< /tabs >}}

## Wait for OpenBao to become ready

Wait for the rollout to complete:

```shell
kubectl -n openbao rollout status deployment openbao
```

For colocated clusters, pods previously in a `CrashLoopBackOff` state become healthy
after `gitlab-ctl reconfigure` completes.

## Verify the installation

To verify the installation:

1. Verify that OpenBao is reachable:

   ```shell
   curl "https://openbao.example.com/v1/sys/health"
   ```

   A successful response looks like:

   ```json
   {
     "initialized": true,
     "sealed": false,
     "standby": false,
     "version": "2.0.0"
   }
   ```

1. [Enable the GitLab Secrets Manager](../../ci/secrets/secrets_manager/_index.md#enable-or-disable-the-gitlab-secrets-manager).
