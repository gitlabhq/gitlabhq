---
stage: GitLab Dedicated
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Troubleshooting Geo SSH response code errors
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

## SSH pull and push hang indefinitely on Cloud Native deployments using NGINX Ingress

> [!note]
> This problem only affects Cloud Native GitLab deployments using the bundled NGINX Ingress.
> Deployments using Envoy as the Ingress controller are not affected by this issue.

SSH push and pull from a secondary site deployed using Helm Chart can hang indefinitely
when the following feature flags are enabled:

- `geo_proxy_fetch_ssh_to_primary`
- `geo_proxy_push_ssh_to_primary`

These flags change the SSH proxy path for Git operations initiated against a Geo secondary. They have been enabled
by default in GitLab version 19.4.0 and above.

The problem is caused by NGINX request buffering on the webservice Ingress. GitLab Shell sends a streaming request body
while the Git client waits for the ref advertisement; NGINX waits for the request body and the Git client waits for the
response, so the request does not reach Workhorse.

To fix this, choose the option that matches your deployment:

- For GitLab 18.11 and earlier: disable both feature flags:
  - `geo_proxy_fetch_ssh_to_primary`
  - `geo_proxy_push_ssh_to_primary`
- For GitLab 19.0 and later:
  - Upgrade to use [Envoy Gateway](https://docs.gitlab.com/charts/installation/migration/envoy_gateway_migration/) as the Ingress controller.

Do not leave both feature flags enabled while using the bundled NGINX Ingress.
Users may otherwise be unable to complete SSH fetches or pushes through Geo secondaries.

For technical details, see [Geo proxied Git fetch error: fatal: the remote end hung up unexpectedly](https://gitlab.com/gitlab-org/gitlab/-/work_items/454707).

## Error: `Net::ReadTimeout` when pushing through SSH on a Geo secondary

When you push large repositories through SSH on a Geo secondary site, you may encounter a timeout.
This is because Rails proxies the push to the primary and has a 60 second default timeout,
[as described in this Geo issue](https://gitlab.com/gitlab-org/gitlab/-/issues/7405).

Current workarounds are:

- Push through HTTP instead, where Workhorse proxies the request to the primary (or redirects to the primary if Geo proxying is not enabled).
- Push directly to the primary.

Example log (`gitlab-shell.log`):

```plaintext
Failed to contact primary https://primary.domain.com/namespace/push_test.git\\nError: Net::ReadTimeout\",\"result\":null}" code=500 method=POST pid=5483 url="http://127.0.0.1:3000/api/v4/geo/proxy_git_push_ssh/push"
```
