---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Proxying assets
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

A possible security concern when managing a public-facing GitLab instance is
the ability to steal a user's IP address by referencing images in issues and comments.

For example, adding `![An example image.](http://example.com/example.png)` to
an issue description causes the image to be loaded from the external
server to be displayed. However, this also allows the external server
to log the IP address of the user.

One way to mitigate this is by proxying any external images to a server you
control.

GitLab can be configured to use an asset proxy server when requesting external images/videos/audio in
issues and comments. This helps ensure that malicious images do not expose the user's IP address
when they are fetched.

We currently recommend using [cactus/go-camo](https://github.com/cactus/go-camo#how-it-works)
as it supports proxying video, audio, and is more configurable.

## Installing Camo server

A Camo server is used to act as the proxy.

To install a Camo server as an asset proxy:

1. Deploy a `go-camo` server. Helpful instructions can be found in
   [building cactus/go-camo](https://github.com/cactus/go-camo#building).

   {{< alert type="warning" >}}

   Asset Proxy servers should be configured to use correct Content Security Policy headers,
   such as `form-action 'none'` (alongside default `go-camo` headers).

   {{< /alert >}}

1. Make sure your GitLab instance is running, and that you have created a private API token.
   Using the API, configure the asset proxy settings on your GitLab instance. For example:

   ```shell
   curl --request "PUT" "https://gitlab.example.com/api/v4/application/settings?\
   asset_proxy_enabled=true&\
   asset_proxy_url=https://proxy.gitlab.example.com&\
   asset_proxy_secret_key=<somekey>" \
   --header 'PRIVATE-TOKEN: <my_private_token>'
   ```

   The following settings are supported:

   | Attribute                | Description                                                                                                                          |
   |:-------------------------|:-------------------------------------------------------------------------------------------------------------------------------------|
   | `asset_proxy_enabled`    | Enable proxying of assets. If enabled, requires: `asset_proxy_url`.                                                                  |
   | `asset_proxy_secret_key` | Shared secret with the asset proxy server.                                                                                           |
   | `asset_proxy_url`        | URL of the asset proxy server.                                                                                                       |
   | `asset_proxy_whitelist`  | (Deprecated: Use `asset_proxy_allowlist` instead) Assets that match these domains are NOT proxied. Wildcards allowed. Your GitLab installation URL is automatically allowed.         |
   | `asset_proxy_allowlist`  | Assets that match these domains are NOT proxied. Wildcards allowed. Your GitLab installation URL is automatically allowed.         |

1. Restart the server for the changes to take effect. Each time you change any values for the asset
   proxy, you need to restart the server.

## Using the Camo server

Once the Camo server is running and you've enabled the GitLab settings, any image, video, or audio that
references an external source are proxied to the Camo server.

For example, the following is a link to an image in Markdown:

```markdown
![A GitLab logo.](https://about.gitlab.com/images/press/logo/jpg/gitlab-icon-rgb.jpg)
```

The following is an example of a source link that could result:

```plaintext
http://proxy.gitlab.example.com/f9dd2b40157757eb82afeedbf1290ffb67a3aeeb/68747470733a2f2f61626f75742e6769746c61622e636f6d2f696d616765732f70726573732f6c6f676f2f6a70672f6769746c61622d69636f6e2d7267622e6a7067
```
