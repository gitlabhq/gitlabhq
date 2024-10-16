---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Learn about the GitLab Language Server."
---

# GitLab Language Server

The [GitLab Language Server](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp) powers various GitLab editor extensions across IDEs.

## Network connectivity

### Configure the language server to use a proxy

The `gitlab-lsp` child process uses the [`proxy-from-env`](https://www.npmjs.com/package/proxy-from-env?activeTab=readme) NPM module to determine proxy settings from the following environment variables:

- `NO_PROXY`
- `HTTPS_PROXY`
- `HTTP_PROXY`

Track the feature request to [support proxy authentication](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/159) from the language server which proposes explicit support for authenticated HTTP(S) proxies.

::Tabs

:::TabTitle Visual Studio Code

1. Open your user or workspace [settings](https://code.visualstudio.com/docs/getstarted/settings).
1. Configure `http.proxySupport` and related settings.

You might encounter an error similar to `407 Access Denied (authentication_failed)`
if you're using an authenticated proxy:

```plaintext
Request failed: Can't add GitLab account for https://gitlab.com. Check your instance URL and network connection.
Fetching resource from https://gitlab.com/api/v4/personal_access_tokens/self failed
```

GitLab Duo Code Suggestions does not support authenticated proxies. For the proposed feature,
see [issue 1234](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1234).

:::TabTitle JetBrains IDEs

1. Configure [HTTP Proxy](https://www.jetbrains.com/help/idea/settings-http-proxy.html) settings in your JetBrains IDE.
1. Restart the IDE.

::EndTabs
