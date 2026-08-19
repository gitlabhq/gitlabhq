---
stage: Security Platform
group: Secrets Manager OpenBao
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Install OpenBao for a Linux package deployment of GitLab
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/9669) as a beta feature in GitLab 19.0.
- Automatic database and role creation [added](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9440) in GitLab 19.2.
- Helm values generation [added](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9290) in GitLab 19.2.

{{< /history >}}

Use a Kubernetes cluster to run OpenBao alongside a GitLab instance installed
with the Linux package. OpenBao runs in the cluster and connects to a PostgreSQL
database. GitLab Rails and Sidekiq connect to OpenBao over HTTPS.

> [!note]
> This information applies to GitLab 19.2 and later.
> For GitLab 19.0 and 19.1, see the version of this page for your GitLab version in the
> [documentation archives](https://archives.docs.gitlab.com).

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

- GitLab 19.2 or later installed with the Linux package, with administrator access.
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

Before going to production, review [Security hardening](#security-hardening) for additional
recommendations for deployments, particularly when components span multiple hosts.

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

OpenBao stores its data in a PostgreSQL database. How you provision it depends on your PostgreSQL setup:

- Linux package-managed PostgreSQL: the Linux package creates the database and role automatically
  during `gitlab-ctl reconfigure`, based on the `postgresql['component_databases']` setting you
  declare when you configure GitLab by using the instructions below.
- External or managed PostgreSQL: you create the database and role manually, because
  `component_databases` supports only Linux package-managed PostgreSQL.

To prepare the database:

1. Choose a strong password for the OpenBao database user.
   You use this same password in the Kubernetes secret, and either in the
   `postgresql['component_databases']` configuration or when you create the database user manually.

1. Create the Kubernetes namespace and the secret that passes the database password to the Helm
   chart. The secret name and key must match the generated Helm values file:

   ```shell
   kubectl create namespace openbao

   kubectl create secret generic openbao-db-password \
     --namespace openbao \
     --from-literal=password='<strong-password>'
   ```

1. If you use an external or managed PostgreSQL instance, create the database and role manually:

   ```shell
   psql -h <POSTGRES_ADDRESS> -U <admin_user> \
     -c "CREATE USER openbao WITH PASSWORD '<strong-password>';"

   psql -h <POSTGRES_ADDRESS> -U <admin_user> \
     -c "CREATE DATABASE openbao OWNER openbao;"
   ```

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

# Local GitLab services (Rails, container registry) connect to the shared
# network IP address over TCP instead of the Unix socket, so include it in
# the trusted CIDR blocks.
postgresql['trust_auth_cidr_addresses'] = %w[127.0.0.1/32 ::1/128 <SHARED_NETWORK_IP>/32]

# Kubernetes pods authenticate with a password.
# Replace 10.42.0.0/16 with the CIDR of your Kubernetes CNI (pod network).
postgresql['md5_auth_cidr_addresses'] = %w[10.42.0.0/16]

# Create the OpenBao database and role automatically.
# Only for Linux package-managed PostgreSQL, omit for external DB
# Use the same password as the openbao-db-password Kubernetes secret.
postgresql['component_databases'] = {
  'openbao' => {
    'enable'   => true,
    'database' => 'openbao',
    'user'     => 'openbao',
    'password' => '<strong-password>'
  }
}

# Without this setting, NGINX routes all traffic on the shared IP to the
# OpenBao virtual host. Both virtual hosts must listen on the same addresses
# so NGINX can route by server name instead.
nginx['listen_addresses'] = ['*', '<SHARED_NETWORK_IP>']

# OAK: OpenBao reverse proxy via GitLab NGINX.
oak['enable'] = true
oak['network_address'] = '<SHARED_NETWORK_IP>'

oak['components']['openbao']['enable'] = true

# Replace 'https://openbao.example.com' with the URL of the DNS record
# you configured for OpenBao, which resolves to your host's public IP address.
oak['components']['openbao']['external_url'] = 'https://openbao.example.com'

# The internal URL that GitLab NGINX uses to reach the OpenBao service.
# If you use the service clusterIP, set a temporary value now and replace it after
# you install OpenBao. See the Helm installation step.
oak['components']['openbao']['internal_url'] = 'http://127.0.0.1:8200'

# The URL that the GitLab application uses to connect to OpenBao.
gitlab_rails['openbao'] = {
  'url' => 'https://openbao.example.com'
}
```

In this configuration:

- `postgresql['listen_address']` is the shared network IP. Connections from CIDRs not listed
  in `trust_auth_cidr_addresses` or `md5_auth_cidr_addresses` are rejected by PostgreSQL.
- `postgresql['trust_auth_cidr_addresses']` is a list of CIDR blocks that includes localhost and
  the shared network IP. Connections from these blocks don't require a password. The shared
  network IP is required because local GitLab services connect to it over TCP instead of using
  the Unix socket.
- `postgresql['md5_auth_cidr_addresses']` is a list of CIDR blocks from the pod CIDR. Connections
  from these blocks require a password. These addresses are used by OpenBao pods.
- `postgresql['component_databases']` declares the OpenBao database and role. The Linux package
  creates them during `gitlab-ctl reconfigure`. If you use an external or managed instance, omit this setting.
- `nginx['listen_addresses']` specifies the addresses that the GitLab and OpenBao NGINX virtual
  hosts listen on. Both virtual hosts must listen on the same addresses so NGINX can route
  requests by server name instead of preferring the most specific listen address.
- `oak['network_address']` is the shared network IP. Used by NGINX listen directives.
- `oak['components']['openbao']['internal_url']` is the URL used by the GitLab application
  to talk to OpenBao.
- `gitlab_rails['openbao']['url']` is the OpenBao URL used by the GitLab application.

Choose the internal URL based on how OpenBao is exposed in your cluster:

- Load balancer or `nodePort`. The URL is known before you install OpenBao, so you can set it now
  and finish in a single reconfigure. For a load balancer, configure DNS so the internal URL
  resolves to the load balancer IP address.
- Service `clusterIP`. The `clusterIP` is assigned only after Helm creates the service. Set a
  temporary `internal_url` now, then update it after you install OpenBao.

The host machine must be able to reach the internal URL IP from outside your Kubernetes cluster.
Configure your cluster to allocate IPs from your chosen `<SHARED_NETWORK_IP>`.

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

Add the following to `/etc/gitlab/gitlab.rb` on each GitLab application node, replacing the
placeholder values with your actual addresses and domain:

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

# Create the OpenBao database and role automatically.
# Use the same password as the openbao-db-password Kubernetes secret.
# Only for Linux package-managed PostgreSQL, omit for external DB
postgresql['component_databases'] = {
  'openbao' => {
    'enable'   => true,
    'database' => 'openbao',
    'user'     => 'openbao',
    'password' => '<strong-password>'
  }
}
```

Add these CIDR entries to your existing `trust_auth_cidr_addresses` and
`md5_auth_cidr_addresses` values instead of replacing them. Keep your existing entries for
other GitLab nodes, such as Rails and Sidekiq nodes.

For an external or managed PostgreSQL instance, omit the `component_databases` block and create the
database and role manually, as described in
[Provision the OpenBao PostgreSQL database](#provision-the-openbao-postgresql-database).

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

- The OpenBao database and role are created.
- PostgreSQL starts accepting TCP connections from Kubernetes pods.
- NGINX is configured with the OpenBao virtual host, including TLS termination
  and HTTP to HTTPS redirect.
- The Let's Encrypt certificate is issued or renewed, if applicable.
- The Helm values file is generated at `/etc/gitlab/openbao-helm-values.yaml`.

Reconfigure fails if `oak['components']['openbao']['external_url']` or `oak['components']['openbao']['internal_url']` is not set.

{{< /tab >}}

{{< tab title="External cluster" >}}

Apply configuration changes on each node where you updated `gitlab.rb`:

```shell
sudo gitlab-ctl reconfigure
```

On the PostgreSQL node, this creates the OpenBao database and role, and makes PostgreSQL accept TCP
connections from the cluster pod network. On Rails and Sidekiq nodes, this applies the OpenBao URL
configuration.

{{< /tab >}}

{{< /tabs >}}

## Install OpenBao by using Helm

{{< tabs >}}

{{< tab title="Colocated cluster" >}}

To install OpenBao by using Helm:

1. Add the GitLab Helm repository:

   ```shell
   helm repo add gitlab https://charts.gitlab.io
   helm repo update
   ```

1. Install OpenBao with the generated values file:

   ```shell
   helm upgrade --install openbao gitlab/openbao \
     --namespace openbao \
     --values /etc/gitlab/openbao-helm-values.yaml
   ```

   The generated file configures PostgreSQL storage, high availability, and JWT initialization.
   It does not configure `ingress`, `ui`, or `gatewayRoute` because the colocated cluster reaches
   OpenBao through Linux package-managed NGINX.

   For all available chart options, see the
   [OpenBao Helm chart documentation](https://docs.gitlab.com/charts/charts/openbao/).

1. Optional. If you use the service `clusterIP` as the internal URL, finalize it now. Read the
   assigned `clusterIP`:

   ```shell
   kubectl -n openbao get svc openbao-active \
     -o jsonpath='{.spec.clusterIP}'
   ```

   Set the internal URL in `/etc/gitlab/gitlab.rb`:

   ```ruby
   oak['components']['openbao']['internal_url'] = 'http://<CLUSTER_IP>:8200'
   ```

   Then reconfigure again:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   If you use a load balancer or `nodePort` internal URL, this step is not required because the
   URL is known when you configure GitLab.

{{< /tab >}}

{{< tab title="External cluster" >}}

To install OpenBao by using Helm:

1. Add the GitLab Helm repository:

   ```shell
   helm repo add gitlab https://charts.gitlab.io
   helm repo update
   ```

1. Create an `openbao-values.yaml` file with the following content, replacing the
   placeholder values with your actual domains and PostgreSQL address. The password comes from the
   `openbao-db-password` secret:

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
             secret: openbao-db-password
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

## Wait for OpenBao to become ready

Wait for the rollout to complete:

```shell
kubectl -n openbao rollout status deployment openbao
```

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

1. [Enable the GitLab Secrets Manager](../../ci/secrets/secrets_manager/_index.md#enable-gitlab-secrets-manager).

## Security hardening

The following recommendations help you reduce risk when running OpenBao with the Linux package in production.
Most of the underlying controls depend on choices in your Kubernetes distribution and the
surrounding infrastructure, which GitLab does not manage.

For general GitLab hardening recommendations, see
[GitLab hardening recommendations](../../security/hardening.md).

### Encrypt traffic between components

In a single-host colocated installation, traffic between Rails, Sidekiq, OpenBao, and PostgreSQL
stays on the host's shared network and is not exposed outside the host. As soon as the topology
spans multiple hosts (for example, an external cluster or an external PostgreSQL instance),
unencrypted traffic between components travels over the network
and is exposed to anyone with access to it.

Encrypt traffic between components, including the OpenBao connection to PostgreSQL, using either:

- Application-layer mTLS.
- TLS with load balancer offloading.
- A dedicated network-layer.

In multi-node topologies, encryption applies to traffic between Kubernetes pods, nodes, and Linux package nodes.
Refer to your Kubernetes distribution, CNI, and database documentation for the configuration
steps that apply to your environment.

### Encrypt the Kubernetes datastore

The Kubernetes datastore (`etcd` for most distributions) stores Kubernetes `Secret` objects
without encryption by default. The OpenBao Helm chart stores the unseal key as a Kubernetes
`Secret`, so a compromise of the datastore exposes the key that grants access to the entire
OpenBao vault.

Enable encryption at rest for Kubernetes Secrets in your distribution. Alternatively,
configure OpenBao auto-unseal with a key management service (KMS) so that the unseal key
is not stored in a Kubernetes Secret. For chart options, see the
[OpenBao Helm chart documentation](https://docs.gitlab.com/charts/charts/openbao/).

### Restrict pod-to-host network access

The Linux package PostgreSQL accepts TCP connections from the entire Kubernetes pod CIDR you
set in `postgresql['md5_auth_cidr_addresses']`. Any pod scheduled in that cluster, including
workloads unrelated to OpenBao, can reach PostgreSQL and NGINX on the shared network. Only
application-layer controls, such as PostgreSQL passwords and JWT validation, protect those
services from access by other pods.

To limit this exposure:

- If the cluster is shared with other workloads, use a CNI that enforces Kubernetes
  `NetworkPolicy`. Some distributions do not enforce `NetworkPolicy` by default, including k3s
  with its default CNI.
- Narrow `postgresql['md5_auth_cidr_addresses']` to the smallest CIDR that covers OpenBao pods.

### Limit Kubernetes API server exposure

Several Kubernetes distributions bind the API server to `0.0.0.0` by default.
An exposed API server provides a direct path into the cluster and, by extension, to OpenBao.
Bind the API server to a local interface or to the shared network IP, and restrict
reachability with firewall or security group rules.
