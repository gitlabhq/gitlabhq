A possible security concern when managing a public facing GitLab instance is
the ability to steal a users IP address by referencing images in issues, comments, etc.

For example, adding `![Example image](http://example.com/example.png)` to
an issue description will cause the image to be loaded from the external
server in order to be displayed.  However this also allows the external server
to log the IP address of the user.

One way to mitigate this is by proxying any external images to a server you
control.  GitLab handles this by allowing you to run the "Camo" server
[cactus/go-camo](https://github.com/cactus/go-camo#how-it-works).
The image request is sent to the Camo server, which then makes the request for
the original image.  This way an attacker only ever seems the IP address
of your Camo server.

Once you have your Camo server up and running, you can configure GitLab to
proxy image requests to it.  The following settings are supported:

| Attribute                | Description |
| ------------------------ | ----------- |
| `asset_proxy_enabled`    | (**If enabled, requires:** `asset_proxy_url`) Enable proxying of assets. |
| `asset_proxy_secret_key` | Shared secret with the asset proxy server. |
| `asset_proxy_url`        | URL of the asset proxy server. |
| `asset_proxy_whitelist`  | Assets that match these domain(s) will NOT be proxied. Wildcards allowed. Your GitLab installation URL is automatically whitelisted. |

These can be set via the [Application setting API](../api/settings.md)

Note that a GitLab restart is required to apply any changes.
