---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab言語サーバーについて学習します。
title: GitLab言語サーバー
---

[GitLab言語サーバー](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp)は、さまざまなGitLabエディタ拡張機能をIDE間で強化します。

## プロキシを使用するように言語サーバーを設定する {#configure-the-language-server-to-use-a-proxy}

`gitlab-lsp`子プロセスは、[`proxy-from-env`](https://www.npmjs.com/package/proxy-from-env?activeTab=readme) NPMモジュールを使用して、これらの環境変数からプロキシ設定を決定します:

- `NO_PROXY`
- `HTTPS_PROXY`
- `http_proxy` (小文字)

プロキシを使用するように言語サーバーを設定するには:

{{< tabs >}}

{{< tab title="Visual Studio Code" >}}

1. VS Codeで、[ユーザーまたはワークスペースの設定](https://code.visualstudio.com/docs/getstarted/settings)を開きます。
1. HTTPプロキシを指すように[`http.proxy`](https://code.visualstudio.com/docs/setup/network#_legacy-proxy-server-support)を設定します。
1. VS Codeを再起動して、GitLabへの接続が最新のプロキシ設定を使用していることを確認してください。

{{< /tab >}}

{{< tab title="JetBrains IDE" >}}

1. JetBrainsIDEで、[HTTP Proxy](https://www.jetbrains.com/help/idea/settings-http-proxy.html)設定を設定します。
1. IDEを再起動して、GitLabへの接続が最新のプロキシ設定を使用していることを確認してください。
1. **Tools** > **GitLab Duo**メニューから、**Verify setup**を選択します。ヘルスチェックに合格することを確認してください。

{{< /tab >}}

{{< /tabs >}}

## トラブルシューティング {#troubleshooting}

### エディタ拡張機能を更新する {#update-your-editor-extension}

言語サーバーは、GitLab用の各エディタ拡張機能にバンドルされています。最新の機能とバグ修正が利用できるように、拡張機能を最新バージョンに更新してください:

- 更新手順[for Eclipse](../eclipse/_index.md#update-the-plugin)
- 更新手順[for JetBrains IDEs](../jetbrains_ide/_index.md#update-the-extension)
- 更新手順[for Neovim](../neovim/_index.md#update-the-extension)
- 更新手順[for Visual Studio](../visual_studio/_index.md#update-the-extension)
- 更新手順[for VS Code](../visual_studio_code/_index.md#update-the-extension)

### プロキシ認証を有効にする {#enable-proxy-authentication}

認証されたプロキシを使用している場合、`407 Access Denied (authentication_failed)`エラーが発生する可能性があります:

```plaintext
Request failed: Can't add GitLab account for https://gitlab.com. Check your instance URL and network connection.
Fetching resource from https://gitlab.com/api/v4/personal_access_tokens/self failed
```

言語サーバーでプロキシ認証を有効にするには、IDEの手順に従ってください:

{{< tabs >}}

{{< tab title="Visual Studio Code" >}}

1. VS Codeで、[ユーザーまたはワークスペースの設定](https://code.visualstudio.com/docs/getstarted/settings)を開きます。
1. HTTPプロキシで認証するために、ユーザー名とパスワードを含め、[`http.proxy`](https://code.visualstudio.com/docs/setup/network#_legacy-proxy-server-support)を設定します。
1. VS Codeを再起動して、GitLabへの接続が最新のプロキシ設定を使用していることを確認してください。

> [!note]
> VS Code拡張機能は、言語サーバーをHTTPプロキシで認証するためのVS Codeの従来の[`http.proxyAuthorization`](https://code.visualstudio.com/docs/setup/network#_legacy-proxy-server-support)設定をサポートしていません。この機能は[イシュー1672](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1672)で提案されています。

{{< /tab >}}

{{< tab title="JetBrains IDE" >}}

1. JetBrainsIDEで、[HTTP Proxy](https://www.jetbrains.com/help/idea/settings-http-proxy.html)設定を設定します。
   1. **Manual proxy configuration**を使用している場合は、**Proxy authentication**の下に認証情報を入力し、**Remember**を選択します。
1. JetBrainsIDEを再起動して、GitLabへの接続が最新のプロキシ設定を使用していることを確認してください。
1. **Tools** > **GitLab Duo**メニューから、**Verify setup**を選択します。ヘルスチェックに合格することを確認してください。

{{< /tab >}}

{{< /tabs >}}

> [!note]
> Bearer認証は[イシュー548](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/548)で提案されています。

## 関連トピック {#related-topics}

- [GitLab言語サーバーリリース](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases)
