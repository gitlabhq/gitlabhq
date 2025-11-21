---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab言語サーバーについて説明します。
title: GitLab言語サーバーについて
---

[GitLab言語サーバー](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp)は、IDEs全体のさまざまなGitLabエディタ拡張機能を強化します。

## 言語サーバーがプロキシを使用するように設定する {#configure-the-language-server-to-use-a-proxy}

`gitlab-lsp`子プロセスは、これらの環境変数からプロキシ設定を判別するために、[`proxy-from-env`](https://www.npmjs.com/package/proxy-from-env?activeTab=readme) NPMモジュールを使用します:

- `NO_PROXY`
- `HTTPS_PROXY`
- `http_proxy` (小文字)

言語サーバーがプロキシを使用するように設定するには:

{{< tabs >}}

{{< tab title="Visual Studio Code" >}}

1. Visual Studioコードで、[ユーザーまたはワークスペース設定](https://code.visualstudio.com/docs/getstarted/settings)を開きます。
1. HTTPプロキシを指すように[`http.proxy`](https://code.visualstudio.com/docs/setup/network#_legacy-proxy-server-support)を設定します。
1. GitLabへの接続で最新のプロキシ設定が使用されるように、Visual Studioコードを再起動します。

{{< /tab >}}

{{< tab title="JetBrains IDE" >}}

1. JetBrains IDEで、[HTTPプロキシ](https://www.jetbrains.com/help/idea/settings-http-proxy.html)設定を設定します。
1. GitLabへの接続で最新のプロキシ設定が使用されるように、IDEを再起動します。
1. **ツール** > **GitLab Duo**メニューから、**Verify setup**（セットアップの検証）を選択します。ヘルスチェックがパスしていることを確認してください。

{{< /tab >}}

{{< /tabs >}}

## トラブルシューティング {#troubleshooting}

### エディタ拡張機能を更新する {#update-your-editor-extension}

言語サーバーは、GitLab用の各エディタ拡張機能にバンドルされています。最新の機能とバグ修正を利用できるようにするには、拡張機能の最新バージョンに更新してください:

- 更新手順[（Eclipseの場合）](../eclipse/_index.md#update-the-plugin)
- 更新手順[（JetBrains IDEの場合）](../jetbrains_ide/_index.md#update-the-extension)
- 更新手順[（Neovimの場合）](../neovim/_index.md#update-the-extension)
- 更新手順[（Visual Studioの場合）](../visual_studio/_index.md#update-the-extension)
- 更新手順[（Visual Studio Codeの場合）](../visual_studio_code/_index.md#update-the-extension)

### プロキシ認証を有効にする {#enable-proxy-authentication}

認証されたプロキシを使用している場合、`407 Access Denied (authentication_failed)`エラーが発生する可能性があります:

```plaintext
Request failed: Can't add GitLab account for https://gitlab.com. Check your instance URL and network connection.
Fetching resource from https://gitlab.com/api/v4/personal_access_tokens/self failed
```

言語サーバーでプロキシ認証を有効にするには、IDEの手順に従ってください:

{{< tabs >}}

{{< tab title="Visual Studio Code" >}}

1. ユーザーまたはワークスペースの[設定](https://code.visualstudio.com/docs/getstarted/settings)を開きます。
1. HTTPプロキシで認証するために、ユーザー名とパスワードを含め、[`http.proxy`](https://code.visualstudio.com/docs/setup/network#_legacy-proxy-server-support)を設定します。
1. GitLabへの接続で最新のプロキシ設定が使用されるように、Visual Studioコードを再起動します。

{{< alert type="note" >}}

VSコード拡張機能は、HTTPプロキシで言語サーバーを認証するための、VSコードの従来の[`http.proxyAuthorization`](https://code.visualstudio.com/docs/setup/network#_legacy-proxy-server-support)設定をサポートしていません。[イシュー1672](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1672)でサポートが提案されています。

{{< /alert >}}

{{< /tab >}}

{{< tab title="JetBrains IDE" >}}

1. JetBrains IDEで[HTTPプロキシ](https://www.jetbrains.com/help/idea/settings-http-proxy.html)設定を設定します。
   1. **Manual proxy configuration**（手動プロキシ設定）を使用している場合は、**Proxy authentication**（プロキシ認証）で認証情報を入力し、**Remember**（記憶する）を選択します。
1. GitLabへの接続で最新のプロキシ設定が使用されるように、JetBrains IDEを再起動します。
1. **ツール** > **GitLab Duo**メニューから、**Verify setup**（セットアップの検証）を選択します。ヘルスチェックがパスしていることを確認してください。

{{< /tab >}}

{{< /tabs >}}

{{< alert type="note" >}}

[イシュー548](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/548)で、ベアラー認証が提案されています。

{{< /alert >}}
