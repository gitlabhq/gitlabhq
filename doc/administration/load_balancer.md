---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Load Balancer for multi-node GitLab
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

In a multi-node GitLab configuration, you need a load balancer to route
traffic to the application servers. The specifics on which load balancer to use
or the exact configuration is beyond the scope of GitLab documentation. We hope
that if you're managing HA systems like GitLab you have a load balancer of
choice already. Some examples including HAProxy (open-source), F5 Big-IP LTM,
and Citrix NetScaler. This documentation outlines what ports and protocols
to use with GitLab.

## SSL

How do you want to handle SSL in your multi-node environment? There are several different
options:

- Each application node terminates SSL
- The load balancers terminate SSL and communication is not secure between
  the load balancers and the application nodes
- The load balancers terminate SSL and communication is *secure* between the
  load balancers and the application nodes

### Application nodes terminate SSL

Configure your load balancers to pass connections on port 443 as 'TCP' rather
than 'HTTP(S)' protocol. This passes the connection to the application nodes
NGINX service untouched. NGINX has the SSL certificate and listen on port 443.

See the [HTTPS documentation](https://docs.gitlab.com/omnibus/settings/ssl/index.html)
for details on managing SSL certificates and configuring NGINX.

### Load Balancers terminate SSL without backend SSL

Configure your load balancers to use the `HTTP(S)` protocol rather than `TCP`.
The load balancers are responsible for managing SSL certificates and
terminating SSL.

Because communication between the load balancers and GitLab isn't secure,
there is some additional configuration needed. See the
[proxied SSL documentation](https://docs.gitlab.com/omnibus/settings/ssl/index.html#configure-a-reverse-proxy-or-load-balancer-ssl-termination)
for details.

### Load Balancers terminate SSL with backend SSL

Configure your load balancers to use the `HTTP(S)` protocol rather than `TCP`.
The load balancers is responsible for managing SSL certificates that
end users see.

Traffic is secure between the load balancers and NGINX in this
scenario. There is no need to add configuration for proxied SSL because the
connection is secure all the way. However, configuration must be
added to GitLab to configure SSL certificates. See
the [HTTPS documentation](https://docs.gitlab.com/omnibus/settings/ssl/index.html)
for details on managing SSL certificates and configuring NGINX.

## Ports

### Basic ports

| LB Port | Backend Port | Protocol                 |
| ------- | ------------ | ------------------------ |
| 80      | 80           | HTTP (*1*)               |
| 443     | 443          | TCP or HTTPS (*1*) (*2*) |
| 22      | 22           | TCP                      |

- (*1*): [Web terminal](../ci/environments/_index.md#web-terminals-deprecated) support requires
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
[GitLab Pages documentation](pages/_index.md) for more information.

| LB Port | Backend Port  | Protocol  |
| ------- | ------------- | --------- |
| 80      | Varies (*1*)  | HTTP      |
| 443     | Varies (*1*)  | TCP (*2*) |

- (*1*): The backend port for GitLab Pages depends on the
  `gitlab_pages['external_http']` and `gitlab_pages['external_https']`
  setting. See [GitLab Pages documentation](pages/_index.md) for more details.
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

It is strongly recommend that multi-node deployments configure load balancers to use the [readiness check](monitoring/health_check.md#readiness) to ensure a node is ready to accept traffic, before routing traffic to it. This is especially important when using Puma, because there is a brief period during a restart where Puma doesn't accept requests.

WARNING:
Using the `all=1` parameter with the readiness check in GitLab versions 15.4 to 15.8 may cause [increased Praefect memory usage](https://gitlab.com/gitlab-org/gitaly/-/issues/4751) and lead to memory errors.

## Troubleshooting

### The health check is returning a `408` HTTP code via the load balancer

If you are using the [AWS Classic Load Balancer](https://docs.aws.amazon.com/en_en/elasticloadbalancing/latest/classic/elb-ssl-security-policy.html#ssl-ciphers)
in GitLab 15.0 or later, you must to enable the `AES256-GCM-SHA384` cipher in NGINX.
See [AES256-GCM-SHA384 SSL cipher no longer allowed by default by NGINX](../update/versions/gitlab_15_changes.md#1500)
for more information.

The default ciphers for a GitLab version can be
viewed in the [`files/gitlab-cookbooks/gitlab/attributes/default.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/gitlab/attributes/default.rb)
file and selecting the Git tag that correlates with your target GitLab version
(for example `15.0.5+ee.0`). If required by your load balancer, you can then define
[custom SSL ciphers](https://docs.gitlab.com/omnibus/settings/ssl/index.html#use-custom-ssl-ciphers)
for NGINX.

### Some pages and links are downloaded instead of rendered in the browser

Some GitLab features require the use of WebSockets. In some scenarios where WebSockets support is not enabled on your load balancer, you could experience some links or pages downloading instead of being rendered in the browser. The files downloaded may contain content that look like the following:

```plaintext
One or more reserved bits are on: reserved1 = 1, reserved2 = 0, reserved3 = 0
```

Your load balancer must be capable of supporting HTTP WebSocket requests. If links are downloading this way, check your load balancer configuration and ensure that HTTP WebSocket requests are enabled.
