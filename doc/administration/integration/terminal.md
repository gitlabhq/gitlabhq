---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Web terminals (deprecated)
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Disabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/353410) in GitLab 15.0.

{{< /history >}}

{{< alert type="warning" >}}

This feature was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.

{{< /alert >}}

{{< alert type="flag" >}}

On GitLab Self-Managed, by default this feature is not available. To make it available, an administrator can [enable the feature flag](../feature_flags/_index.md) named `certificate_based_clusters`.

{{< /alert >}}

- Read more about the non-deprecated [Web Terminals accessible through the Web IDE](../../user/project/web_ide/_index.md).
- Read more about the non-deprecated [Web Terminals accessible from a running CI job](../../ci/interactive_web_terminal/_index.md).

---

With the introduction of the [Kubernetes integration](../../user/infrastructure/clusters/_index.md),
GitLab can store and use credentials for a Kubernetes cluster.
GitLab uses these credentials to provide access to
[web terminals](../../ci/environments/_index.md#web-terminals-deprecated) for environments.

{{< alert type="note" >}}

Only users with at least the [Maintainer role](../../user/permissions.md) for the project access web terminals.

{{< /alert >}}

## How web terminals work

A detailed overview of the architecture of web terminals and how they work
can be found in [this document](https://gitlab.com/gitlab-org/gitlab-workhorse/blob/master/doc/channel.md).
In brief:

- GitLab relies on the user to provide their own Kubernetes credentials, and to
  appropriately label the pods they create when deploying.
- When a user goes to the terminal page for an environment, they are served
  a JavaScript application that opens a WebSocket connection back to GitLab.
- The WebSocket is handled in [Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse),
  rather than the Rails application server.
- Workhorse queries Rails for connection details and user permissions. Rails
  queries Kubernetes for them in the background using [Sidekiq](../sidekiq/sidekiq_troubleshooting.md).
- Workhorse acts as a proxy server between the user's browser and the Kubernetes
  API, passing WebSocket frames between the two.
- Workhorse regularly polls Rails, terminating the WebSocket connection if the
  user no longer has permission to access the terminal, or if the connection
  details have changed.

## Security

GitLab and [GitLab Runner](https://docs.gitlab.com/runner/) take some
precautions to keep interactive web terminal data encrypted between them, and
everything protected with authorization guards. This is described in more
detail below.

- Interactive web terminals are completely disabled unless [`[session_server]`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-session_server-section) is configured.
- Every time the runner starts, it generates an `x509` certificate that is used for a `wss` (Web Socket Secure) connection.
- For every created job, a random URL is generated which is discarded at the end of the job. This URL is used to establish a web socket connection. The URL for the session is in the format `(IP|HOST):PORT/session/$SOME_HASH`, where the `IP/HOST` and `PORT` are the configured [`listen_address`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-session_server-section).
- Every session URL that is created has an authorization header that needs to be sent, to establish a `wss` connection.
- The session URL is not exposed to the users in any way. GitLab holds all the state internally and proxies accordingly.

## Enabling and disabling terminal support

{{< alert type="note" >}}

AWS Classic Load Balancers do not support web sockets.
If you want web terminals to work, use AWS Network Load Balancers.
Read [AWS Elastic Load Balancing Product Comparison](https://aws.amazon.com/elasticloadbalancing/features/#compare)
for more information.

{{< /alert >}}

As web terminals use WebSockets, every HTTP/HTTPS reverse proxy in front of
Workhorse must be configured to pass the `Connection` and `Upgrade` headers
to the next one in the chain. GitLab is configured by default to do so.

However, if you run a [load balancer](../load_balancer.md) in
front of GitLab, you may need to make some changes to your configuration. These
guides document the necessary steps for a selection of popular reverse proxies:

- [Apache](https://httpd.apache.org/docs/2.4/mod/mod_proxy_wstunnel.html)
- [NGINX](https://www.f5.com/company/blog/nginx/websocket-nginx/)
- [HAProxy](https://www.haproxy.com/blog/websockets-load-balancing-with-haproxy)
- [Varnish](https://varnish-cache.org/docs/4.1/users-guide/vcl-example-websockets.html)

Workhorse doesn't let WebSocket requests through to non-WebSocket endpoints, so
it's safe to enable support for these headers globally. If you prefer a
narrower set of rules, you can restrict it to URLs ending with `/terminal.ws`.
This approach may still result in a few false positives.

If you self-compiled your installation, you may need to make some changes to your configuration. Read
[Upgrading Community Edition and Enterprise Edition from source](../../update/upgrading_from_source.md#new-configuration-for-nginx-or-apache)
for more details.

To disable web terminal support in GitLab, stop passing
the `Connection` and `Upgrade` hop-by-hop headers in the first HTTP reverse
proxy in the chain. For most users, this is the NGINX server bundled with
Linux package installations. In this case, you need to:

- Find the `nginx['proxy_set_headers']` section of your `gitlab.rb` file
- Ensure the whole block is uncommented, and then comment out or remove the
  `Connection` and `Upgrade` lines.

For your own load balancer, just reverse the configuration changes recommended
by the previously listed guides.

When these headers are not passed through, Workhorse returns a
`400 Bad Request` response to users attempting to use a web terminal. In turn,
they receive a `Connection failed` message.

## Limiting WebSocket connection time

By default, terminal sessions do not expire. To limit the terminal session
lifetime in your GitLab instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Web terminal**.
1. Set a `max session time`.
