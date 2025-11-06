---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Learn about the GitLab Language Server.
title: GitLab Language Server
---

The [GitLab Language Server](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp)
powers various GitLab editor extensions across IDEs.

## Configure the Language Server to use a proxy

The `gitlab-lsp` child process uses the [`proxy-from-env`](https://www.npmjs.com/package/proxy-from-env?activeTab=readme)
NPM module to determine proxy settings from these environment variables:

- `NO_PROXY`
- `HTTPS_PROXY`
- `http_proxy` (in lowercase)

To configure the Language Server to use a proxy:

{{< tabs >}}

{{< tab title="Visual Studio Code" >}}

1. In Visual Studio Code, open your [user or workspace settings](https://code.visualstudio.com/docs/getstarted/settings).
1. Configure [`http.proxy`](https://code.visualstudio.com/docs/setup/network#_legacy-proxy-server-support)
   to point at your HTTP proxy.
1. Restart Visual Studio Code to ensure connections to GitLab use the latest proxy settings.

{{< /tab >}}

{{< tab title="JetBrains IDEs" >}}

1. In your JetBrains IDE, configure the [HTTP Proxy](https://www.jetbrains.com/help/idea/settings-http-proxy.html) settings.
1. Restart your IDE to ensure connections to GitLab use the latest proxy settings.
1. From the **Tools** > **GitLab Duo** menu, select **Verify setup**. Make sure the health check passes.

{{< /tab >}}

{{< /tabs >}}

## Troubleshooting

### Update your editor extension

The Language Server is bundled with each editor extension for GitLab. To ensure you have the latest features and bug fixes
available, update to the latest version of your extension:

- Update instructions [for Eclipse](../eclipse/_index.md#update-the-plugin)
- Update instructions [for JetBrains IDEs](../jetbrains_ide/_index.md#update-the-extension)
- Update instructions [for Neovim](../neovim/_index.md#update-the-extension)
- Update instructions [for Visual Studio](../visual_studio/_index.md#update-the-extension)
- Update instructions [for Visual Studio Code](../visual_studio_code/_index.md#update-the-extension)

### Enable proxy authentication

You might encounter a `407 Access Denied (authentication_failed)` error when using an authenticated proxy:

```plaintext
Request failed: Can't add GitLab account for https://gitlab.com. Check your instance URL and network connection.
Fetching resource from https://gitlab.com/api/v4/personal_access_tokens/self failed
```

To enable proxy authentication in the Language Server, follow the steps for your IDE:

{{< tabs >}}

{{< tab title="Visual Studio Code" >}}

1. Open your user or workspace [settings](https://code.visualstudio.com/docs/getstarted/settings).
1. Configure [`http.proxy`](https://code.visualstudio.com/docs/setup/network#_legacy-proxy-server-support),
   including username and password, to authenticate with your HTTP proxy.
1. Restart Visual Studio Code to ensure connections to GitLab use the latest proxy settings.

{{< alert type="note" >}}

The VS Code extension does not support the legacy
[`http.proxyAuthorization`](https://code.visualstudio.com/docs/setup/network#_legacy-proxy-server-support)
setting in VS Code for authenticating the language server with an HTTP proxy. Support is proposed in
[issue 1672](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1672).

{{< /alert >}}

{{< /tab >}}

{{< tab title="JetBrains IDEs" >}}

1. Configure [HTTP Proxy](https://www.jetbrains.com/help/idea/settings-http-proxy.html) settings in your JetBrains IDE.
   1. If using **Manual proxy configuration**, enter your credentials under **Proxy authentication** and select **Remember**.
1. Restart your JetBrains IDE to ensure connections to GitLab use the latest proxy settings.
1. From the **Tools** > **GitLab Duo** menu, select **Verify setup**. Make sure the health check passes.

{{< /tab >}}

{{< /tabs >}}

{{< alert type="note" >}}

Bearer authentication is proposed in [issue 548](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/548).

{{< /alert >}}
