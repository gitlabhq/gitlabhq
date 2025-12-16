---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: コード提案における一般的な問題のトラブルシューティングのヒント。
title: トラブルシューティングコード提案
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise、GitLab Duo with Amazon Q
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- GitLab 18.0でGitLab Duo Coreを含めるように変更しました。

{{< /history >}}

GitLab Duoコード提案を使用する際、以下の問題が発生する可能性があります。

インスタンスがコード提案を実行するための要件を満たしているかどうかをテストするには、[ヘルスチェック](../../../gitlab_duo/turn_on_off.md)を実行します。

GitLab Duoのトラブルシューティングに関する詳細は、以下を参照してください:

- [GitLab Duo](../../../gitlab_duo/troubleshooting.md)のトラブルシューティング。
- [GitLab Duo](../../../gitlab_duo_chat/troubleshooting.md)チャットのトラブルシューティング。
- [GitLab Duo Self-Hostedのトラブルシューティング](../../../../administration/gitlab_duo_self_hosted/troubleshooting.md)。

## 提案が表示されない {#suggestions-are-not-displayed}

提案が表示されない場合は、以下を確認してください:

- [GitLab Duoが正しく構成されている](../../../gitlab_duo/turn_on_off.md)。
- [サポートされている言語](supported_extensions.md#supported-languages-by-ide)と[エディタ拡張機能](supported_extensions.md#supported-editor-extensions)を使用している。
- [エディタ拡張機能が正しく構成されている](set_up.md#configure-editor-extension)。

提案がまだ表示されない場合は、IDEごとに以下のトラブルシューティング手順を試してください:

- [VS CodeまたはGitLab Web IDE](#suggestions-not-displayed-in-vs-code-or-gitlab-web-ide)
- [JetBrains IDE](#suggestions-not-displayed-in-jetbrains-ides)
- [Microsoft Visual Studio](#suggestions-not-displayed-in-microsoft-visual-studio)

## コード提案が401エラーを返す {#code-suggestions-returns-a-401-error}

コード提案は、GitLabとの[サブスクリプションを同期する](../../../gitlab_duo/_index.md) [ライセンストークンに依存](../../../../administration/license.md)しています。

トークンの有効期限が切れると、トークンの有効期限が切れたときに、GitLab Duoコード提案はステータス`401`で次のエラーを返します:

```plaintext
Token validation failed in Language Server:
(Failed to check token: Error: Fetching Information about personal access token
```

GitLabが[クラウドサーバー](../../../gitlab_duo/_index.md)にアクセスできる場合は、[手動でライセンスを同期](../../../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data)してみてください。

## 認証のトラブルシューティング {#authentication-troubleshooting}

この問題は、認証、特にトークンシステムの最近の変更が原因である可能性があります。この問題を解決するには:

1. 既存のパーソナルアクセストークンをGitLabアカウントの設定から削除します。
1. OAuthを使用して、GitLabアカウントを再認証します。
1. 異なるファイル拡張子でコード提案機能をテストし、問題が解決されたかどうかを確認します。

## VS Codeのトラブルシューティング {#vs-code-troubleshooting}

次のドキュメントは、VS Codeのコード提案固有のトラブルシューティング用です。

VS Codeのコード提案以外のトラブルシューティングについては、[VS Code用GitLab Workflow拡張機能](../../../../editor_extensions/visual_studio_code/troubleshooting.md)のトラブルシューティングを参照してください。

### VS CodeまたはGitLab Web IDEで提案が表示されない {#suggestions-not-displayed-in-vs-code-or-gitlab-web-ide}

GitLab Self-Managedを使用している場合は、[GitLab Web IDE](../../web_ide/_index.md)のコード提案が有効になっていることを確認してください。ローカルIDEとして、VS Codeにも同じ設定が適用されます。

1. 左側のサイドバーで、**Extensions**（拡張機能） > **GitLab Workflow**を選択します。
1. **設定**（{{< icon name="settings" >}}）を選択し、**Extension Settings**（拡張機能の設定）を選択します。
1. **GitLab** > **Duo Code Suggestions**（GitLab Duoコード提案）で、**GitLab Duoコード提案**チェックボックスを選択します。

#### コード提案のログを表示 {#view-code-suggestions-logs}

コード提案がIDEで有効になっているにもかかわらず、提案がまだ表示されない場合:

1. IDEで、GitLab Workflow**Extension Settings**（拡張機能の設定）で、**GitLabを有効にします: デバッグ**。
   - Web IDEの場合は、[マーケットプレイス拡張機能](../../web_ide/_index.md#manage-extensions)が有効になっている必要があります。
1. 上部のメニューで、**表示** > **Output**（出力）を選択して下部のパネルを開き、次のいずれかを行います:
   - コマンドパレットで、`GitLab: Show Extension Logs`を選択します。
   - 下部のパネルの右側で、ドロップダウンリストを選択してログをフィルタリングします。**GitLab Workflow**を選択します。
1. GitLab Workflow**Extension Settings**（拡張機能の設定）で、**GitLab Duoコード提案**チェックボックスをオフにしてから再びオンにします。

### コード生成結果のストリーミングを無効にする {#disable-streaming-of-code-generation-results}

デフォルトでは、コード生成はAIによって生成されたコードをストリーミングします。ストリーミングは、生成されたコードを、コードスニペット全体が生成されるのを待つのではなく、段階的にエディタに送信します。これにより、よりインタラクティブで応答性の高いエクスペリエンスが実現します。

コード生成の結果が完了した場合にのみ表示したい場合は、ストリーミングをオフにできます。ストリーミングを無効にすると、コード生成リクエストの解決に時間がかかると認識される可能性があります。ストリーミングを無効にするには:

1. VS Codeの上部のバーで、**コード** > **設定** > **設定**に移動します。
1. 右上隅にある**Open Settings (JSON)**（設定を開く（JSON））を選択して、`settings.json`ファイルを編集します:

   ![VS Codeの右上隅にあるアイコン（「設定を開く」を含む）](img/open_settings_v17_5.png)
1. `settings.json`ファイルで、この行を追加するか、すでに存在する場合は`false`に設定します:

   ```json
   "gitlab.featureFlags.streamCodeGenerations": false,
   ```

1. 変更を保存します。

### エラー: 直接接続が失敗する {#error-direct-connection-fails}

{{< history >}}

- GitLab 17.2で直接接続が[導入](https://gitlab.com/groups/gitlab-org/-/epics/13252)されました。

{{< /history >}}

レイテンシーを削減するために、Workflow拡張機能は提案のコード補完リクエストをGitLabインスタンスを回避する、GitLab Cloud Connectorに直接送信しようとします。このネットワーキング接続は、VS Code拡張機能のプロキシと証明書の設定を使用しません。

GitLabインスタンスが直接接続をサポートしていない場合、またはネットワーキングによって拡張機能がGitLab Cloud Connectorに接続できない場合は、ログに次の警告が表示されることがあります:

```plaintext
Failed to fetch direct connection details from GitLab instance.
Code suggestion requests will be sent to GitLab instance.
```

このエラーは、インスタンスが直接接続をサポートしていないか、誤って構成されていることを意味します。

このエラーが表示された場合、拡張機能はGitLab Cloud Connectorに接続できず、GitLabインスタンスの使用に戻ります:

```plaintext
Direct connection for code suggestions failed.
Code suggestion requests will be sent to your GitLab instance.
```

GitLabインスタンスを介した間接的な接続は、約100ミリ秒遅くなりますが、それ以外は同じように機能します。この問題は、LANファイアウォールやプロキシの設定など、ネットワーキング接続の問題が原因であることがよくあります。

## JetBrains IDEのトラブルシューティング {#jetbrains-ides-troubleshooting}

次のドキュメントは、JetBrains IDEのコード提案に固有のトラブルシューティング用です。

JetBrains IDEのコード提案以外のトラブルシューティングについては、[JetBrainsのトラブルシューティング](../../../../editor_extensions/jetbrains_ide/jetbrains_troubleshooting.md)を参照してください。

### JetBrains IDEで提案が表示されない {#suggestions-not-displayed-in-jetbrains-ides}

1. **ツール** > **GitLab Duo**メニューから、**Verify setup**（セットアップの確認）を選択します。ヘルスチェックが成功することを確認してください。
1. JetBrains IDEが、作業中のファイルの言語をネイティブでサポートしていることを確認します。**設定** > **Languages & Frameworks**（言語とフレームワーク）に移動して、JetBrains IDEでサポートされている言語とフレームワークの完全なリストを表示します。

### エラー: `unable to find valid certification path to requested target` {#error-unable-to-find-valid-certification-path-to-requested-target}

GitLab Duoプラグインは、GitLabインスタンスに接続する前に、TLS証明書情報を検証します。[カスタムSSL証明書を追加](set_up.md#add-a-custom-certificate-for-code-suggestions)できます。

### エラー: `Failed to check token` {#error-failed-to-check-token}

このエラーは、指定された接続インスタンスのURLと、GitLab言語サーバープロセスに渡された認証トークンが無効な場合に発生します。コード提案を再度有効にするには:

1. IDEで、上部のバーでIDE名を選択し、**設定**を選択します。
1. 左側のサイドバーで、**ツール** > **GitLab Duo**を選択します。
1. **接続**で、**Verify setup**（セットアップの確認）を選択します。
1. 必要に応じて、**接続**の詳細を更新します。
1. **Verify setup**（セットアップの確認）を選択し、認証が成功したことを確認します。
1. **OK**または**保存**を選択します。

## Microsoft Visual Studioのトラブルシューティング {#microsoft-visual-studio-troubleshooting}

次のドキュメントは、Microsoft Visual Studioのコード提案に固有のトラブルシューティング用です。

Microsoft Visual Studioのコード提案以外のトラブルシューティングについては、[Visual Studioのトラブルシューティング](../../../../editor_extensions/visual_studio/visual_studio_troubleshooting.md)を参照してください。

### IntelliCodeが見つからない {#intellicode-is-missing}

コード提案には、Visual StudioのIntelliCodeコンポーネントが必要です。コンポーネントが見つからない場合は、Visual Studioを起動すると、次のようなエラーが表示されることがあります:

```plaintext
SetSite failed for package [VisualStudioPackage]Source: 'Microsoft.VisualStudio.Composition'
Description: Expected 1 export(s) with contract name "Microsoft.VisualStudio.Language.Suggestions.SuggestionServiceBase"
but found 0 after applying applicable constraints.

Microsoft.VisualStudio.Composition.CompositionFailedException:
Expected 1 export(s) with contract name "Microsoft.VisualStudio.Language.Suggestions.SuggestionServiceBase"
but found 0 after applying applicable constraints.

  at Microsoft.VisualStudio.Composition.ExportProvider.GetExports(ImportDefinition importDefinition)
  at Microsoft.VisualStudio.Composition.ExportProvider.GetExports[T,TMetadataView](String contractName, ImportCardinality cardinality)
  at Microsoft.VisualStudio.Composition.ExportProvider.GetExport[T,TMetadataView](String contractName)
  at Microsoft.VisualStudio.Composition.ExportProvider.GetExportedValue[T]()
  at Microsoft.VisualStudio.ComponentModelHost.ComponentModel.GetService[T]()
[...]
```

この問題を修正するには、IntelliCodeコンポーネントをインストールします:

1. Windowsのスタートメニューで、**Visual Studio Installer**（Visual Studioインストーラー）を検索して開きます。
1. Visual Studioインスタンスを選択し、**Modify**（変更）を選択します。
1. **Individual components**（個々のコンポーネント）タブで、**IntelliCode**を検索します。
1. コンポーネントのチェックボックスをオンにしてから、右下の**Modify**（変更）を選択します。
1. Visual Studioインストーラーがインストールを完了するまで待ちます。

### Microsoft Visual Studioで提案が表示されない {#suggestions-not-displayed-in-microsoft-visual-studio}

1. [拡張機能を正しく設定](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension#setup)していることを確認します。
1. **ツール** > **オプション**メニューから、**GitLab**オプションを見つけます。**Log Level**（ログレベル）が**デバッグ**に設定されていることを確認します。
1. **表示** > **Output**（出力）で、拡張機能のログを開きます。ドロップダウンリストをログフィルターとして**GitLab Extension**（GitLab拡張機能）に変更します。
1. デバッグログに同様の出力が含まれていることを確認します:

```shell
14:48:21:344 GitlabProposalSource.GetCodeSuggestionAsync
14:48:21:344 LsClient.SendTextDocumentCompletionAsync("GitLab.Extension.Test\TestData.cs", 34, 0)
14:48:21:346 LS(55096): time="2023-07-17T14:48:21-05:00" level=info msg="update context"
```

別の拡張機能が同様の提案またはコード補完機能を提供している場合、拡張機能は提案を返さない可能性があります。これを解決するには:

1. 他のすべてのVisual Studio拡張機能を無効にします。
1. コード提案を正常に受信できるようになったことを確認します。
1. 競合する拡張機能を見つけるために、一度に1つずつ拡張機能を再度有効にし、毎回コード提案をテストします。

## Neovimのトラブルシューティング {#neovim-troubleshooting}

次のドキュメントは、Neovimのコード提案に固有のトラブルシューティング用です。

Neovimのコード提案以外のトラブルシューティングについては、[Neovimのトラブルシューティング](../../../../editor_extensions/neovim/neovim_troubleshooting.md)を参照してください。

### コード補完が失敗する {#code-completions-fails}

1. `omnifunc`がNeovimに設定されていることを確認します:

   ```lua
   :verbose set omnifunc?
   ```

1. 言語サーバーがアクティブであることを確認するには、Neovimで次のコマンドを実行します:

   ```lua
   :lua =vim.lsp.get_active_clients()
   ```

1. `~/.local/state/nvim/lsp.log`で言語サーバーのログを確認します。
1. Neovimでこのコマンドを実行して、エラーの`vim.lsp`ログパスを調べます:

   ```lua
   :lua =vim.cmd('view ' .. vim.lsp.get_log_path())
   ```
