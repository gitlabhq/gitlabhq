---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Load Balancer for multi-node GitLab **(FREE SELF)**

In an multi-node GitLab configuration, you need a load balancer to route
traffic to the application servers. The specifics on which load balancer to use
or the exact configuration is beyond the scope of GitLab documentation. We hope
that if you're managing HA systems like GitLab you have a load balancer of
choice already. Some examples including HAProxy (open-source), F5 Big-IP LTM,
and Citrix Net Scaler. This documentation outlines what ports and protocols
you need to use with GitLab.

## SSL

How do you want to handle SSL in your multi-node environment? There are several different
options:

- Each application node terminates SSL
- The load balancer(s) terminate SSL and communication is not secure between
  the load balancer(s) and the application nodes
- The load balancer(s) terminate SSL and communication is *secure* between the
  load balancer(s) and the application nodes

### Application nodes terminate SSL

Configure your load balancer(s) to pass connections on port 443 as 'TCP' rather
than 'HTTP(S)' protocol. This passes the connection to the application nodes
NGINX service untouched. NGINX has the SSL certificate and listen on port 443.

See [NGINX HTTPS documentation](https://docs.gitlab.com/omnibus/settings/nginx.html#enable-https)
for details on managing SSL certificates and configuring NGINX.

### Load Balancer(s) terminate SSL without backend SSL

Configure your load balancer(s) to use the 'HTTP(S)' protocol rather than 'TCP'.
The load balancer(s) is be responsible for managing SSL certificates and
terminating SSL.

Since communication between the load balancer(s) and GitLab isn't secure,
there is some additional configuration needed. See
[NGINX Proxied SSL documentation](https://docs.gitlab.com/omnibus/settings/nginx.html#supporting-proxied-ssl)
for details.

### Load Balancer(s) terminate SSL with backend SSL

Configure your load balancer(s) to use the 'HTTP(S)' protocol rather than 'TCP'.
The load balancer(s) is responsible for managing SSL certificates that
end users see.

Traffic is secure between the load balancer(s) and NGINX in this
scenario. There is no need to add configuration for proxied SSL since the
connection is secure all the way. However, configuration must be
added to GitLab to configure SSL certificates. See
[NGINX HTTPS documentation](https://docs.gitlab.com/omnibus/settings/nginx.html#enable-https)
for details on managing SSL certificates and configuring NGINX.

## Ports

### Basic ports

| LB Port | Backend Port | Protocol                 |
| ------- | ------------ | ------------------------ |
| 80      | 80           | HTTP (*1*)               |
| 443     | 443          | TCP or HTTPS (*1*) (*2*) |
| 22      | 22           | TCP                      |

- (*1*): [Web terminal](../ci/environments/index.md#web-terminals) support requires
  your load balancer to correctly handle WebSocket connections. When using
  HTTP or HTTPS proxying, this means your load balancer must be configured
  to pass through the `Connection` and `Upgrade` hop-by-hop headers. See the
  [web terminal](integration/terminal.md) integration guide for
  more details.
- (*2*): When using HTTPS protocol for port 443, you must add an SSL
  certificate to the load balancers. If you wish to terminate SSL at the
  GitLab application server instead, use TCP protocol.

### GitLab Pages Ports

If you're using GitLab Pages with custom domain support you need some
additional port configurations.
GitLab Pages requires a separate virtual IP address. Configure DNS to point the
`pages_external_url` from `/etc/gitlab/gitlab.rb` at the new virtual IP address. See the
[GitLab Pages documentation](pages/index.md) for more information.

| LB Port | Backend Port  | Protocol  |
| ------- | ------------- | --------- |
| 80      | Varies (*1*)  | HTTP      |
| 443     | Varies (*1*)  | TCP (*2*) |

- (*1*): The backend port for GitLab Pages depends on the
  `gitlab_pages['external_http']` and `gitlab_pages['external_https']`
  setting. See [GitLab Pages documentation](pages/index.md) for more details.
- (*2*): Port 443 for GitLab Pages should always use the TCP protocol. Users can
  configure custom domains with custom SSL, which would not be possible
  if SSL was terminated at the load balancer.

### Alternate SSH Port

Some organizations have policies against opening SSH port 22. In this case,
it may be helpful to configure an alternate SSH hostname that allows users
to use SSH on port 443. An alternate SSH hostname requires a new virtual IP address
compared to the other GitLab HTTP configuration above.

Configure DNS for an alternate SSH hostname such as `altssh.gitlab.example.com`.

| LB Port | Backend Port | Protocol |
| ------- | ------------ | -------- |
| 443     | 22           | TCP      |

## Readiness check

It is strongly recommend that multi-node deployments configure load balancers to use the [readiness check](../user/admin_area/monitoring/health_check.md#readiness) to ensure a node is ready to accept traffic, before routing traffic to it. This is especially important when utilizing Puma, as there is a brief period during a restart where Puma doesn't accept requests.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
