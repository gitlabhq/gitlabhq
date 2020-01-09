# Proxying assets

A possible security concern when managing a public facing GitLab instance is
the ability to steal a users IP address by referencing images in issues, comments, etc.

For example, adding `![Example image](http://example.com/example.png)` to
an issue description will cause the image to be loaded from the external
server in order to be displayed. However, this also allows the external server
to log the IP address of the user.

One way to mitigate this is by proxying any external images to a server you
control.

GitLab can be configured to use an asset proxy server when requesting external images/videos/audio in
issues, comments, etc. This helps ensure that malicious images do not expose the user's IP address
when they are fetched.

We currently recommend using [cactus/go-camo](https://github.com/cactus/go-camo#how-it-works)
as it supports proxying video, audio, and is more configurable.

## Installing Camo server

A Camo server is used to act as the proxy.

To install a Camo server as an asset proxy:

1. Deploy a `go-camo` server. Helpful instructions can be found in
   [building catus/go-camo](https://github.com/cactus/go-camo#building).

1. Make sure your instance of GitLab is running, and that you have created a private API token.
   Using the API, configure the asset proxy settings on your GitLab instance. For example:

   ```sh
   curl --request "PUT" "https://gitlab.example.com/api/v4/application/settings?\
   asset_proxy_enabled=true&\
   asset_proxy_url=https://proxy.gitlab.example.com&\
   asset_proxy_secret_key=<somekey>" \
   --header 'PRIVATE-TOKEN: <my_private_token>'
   ```

   The following settings are supported:

   | Attribute                | Description                                                                                                                          |
   |:-------------------------|:-------------------------------------------------------------------------------------------------------------------------------------|
   | `asset_proxy_enabled`    | Enable proxying of assets. If enabled, requires: `asset_proxy_url`).                                                                 |
   | `asset_proxy_secret_key` | Shared secret with the asset proxy server.                                                                                           |
   | `asset_proxy_url`        | URL of the asset proxy server.                                                                                                       |
   | `asset_proxy_whitelist`  | Assets that match these domain(s) will NOT be proxied. Wildcards allowed. Your GitLab installation URL is automatically whitelisted. |

1. Restart the server for the changes to take effect. Each time you change any values for the asset
   proxy, you need to restart the server.

## Using the Camo server

Once the Camo server is running and you've enabled the GitLab settings, any image, video, or audio that
references an external source will get proxied to the Camo server.

For example, the following is a link to an image in Markdown:

```markdown
![logo](https://about.gitlab.com/images/press/logo/jpg/gitlab-icon-rgb.jpg)
```

The following is an example of a source link that could result:

```text
http://proxy.gitlab.example.com/f9dd2b40157757eb82afeedbf1290ffb67a3aeeb/68747470733a2f2f61626f75742e6769746c61622e636f6d2f696d616765732f70726573732f6c6f676f2f6a70672f6769746c61622d69636f6e2d7267622e6a7067
```
