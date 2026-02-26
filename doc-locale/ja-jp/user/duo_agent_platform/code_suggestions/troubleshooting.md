---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: コード提案の一般的な問題に関するトラブルシューティングのヒント。
title: コード提案のトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Duoコード提案を使用する際に、以下の問題が発生する可能性があります。

インスタンスがコード提案を実行するための要件を満たしているかどうかをテストするには、[ヘルスチェック](../../gitlab_duo/turn_on_off.md)を実行します。

GitLab Duoのトラブルシューティングの詳細については、以下を参照してください:

- [GitLab Duoのトラブルシューティング](../../gitlab_duo/troubleshooting.md)。
- [GitLab Duo Chatのトラブルシューティング](../../gitlab_duo_chat/troubleshooting.md)。
- [GitLab Duo Self-Hostedのトラブルシューティング](../../../administration/gitlab_duo_self_hosted/troubleshooting.md)。

## 提案が表示されない {#suggestions-are-not-displayed}

提案が表示されない場合は、以下を確認してください:

- [GitLab Duo](../../gitlab_duo/turn_on_off.md)が正しく設定されていることを確認してください。
- [サポートされている言語](supported_extensions.md#supported-languages-by-ide)と[エディタ拡張機能](supported_extensions.md#supported-editor-extensions)を使用していることを確認してください。
- [エディタ拡張機能](set_up.md#configure-editor-extension)が正しく設定されていることを確認してください。

それでも提案が表示されない場合は、異なるIDEについて、次のトラブルシューティング手順を試してください:

- [VS CodeまたはGitLab Web IDE](#suggestions-not-displayed-in-vs-code-or-gitlab-web-ide)
- [JetBrains IDE](#suggestions-not-displayed-in-jetbrains-ides)
- [Microsoft Visual Studio](#suggestions-not-displayed-in-microsoft-visual-studio)

## コード提案が401エラーを返す {#code-suggestions-returns-a-401-error}

コード提案は、GitLabとの[サブスクリプションを同期](../../../administration/license.md)するトークンに依存しています。

トークンの有効期限が切れると、コード提案はステータス`401`で次のエラーを返します:

```plaintext
Token validation failed in Language Server:
(Failed to check token: Error: Fetching Information about personal access token
```

GitLabがクラウドサーバーにアクセスできる場合は、[ライセンスの手動同期](../../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data)を試してください。

## 認証のトラブルシューティング {#authentication-troubleshooting}

この問題は、認証の最近の変更、特にトークンシステムに起因する可能性があります。この問題を解決するには:

1. 既存のパーソナルアクセストークンをGitLabアカウントの設定から削除します。
1. OAuthを使用してGitLabアカウントを再認証します。
1. さまざまなファイル拡張子でコード提案機能をテストし、問題が解決されたかどうかを確認します。

## VS Codeのトラブルシューティング {#vs-code-troubleshooting}

次のドキュメントは、VS Code固有のコード提案のトラブルシューティングに関するものです。

VS Codeのコード提案以外のトラブルシューティングについては、[VS Code用GitLab Workflow拡張機能](../../../editor_extensions/visual_studio_code/troubleshooting.md)のトラブルシューティングを参照してください。

### VS CodeまたはGitLab Web IDEで提案が表示されない {#suggestions-not-displayed-in-vs-code-or-gitlab-web-ide}

GitLab Self-Managedを使用している場合は、[GitLab Web IDE](../../../user/project/web_ide/_index.md)のコード提案が有効になっていることを確認してください。ローカルIDEとして、同じ設定がVS Codeに適用されます。

1. 左側のサイドバーで、**Extensions** > **GitLab Workflow**を選択します。
1. **管理** ({{< icon name="settings" >}}) を選択し、**設定**を選択します。
1. **GitLab** > **Duo Code Suggestions**で、**GitLab Duoコード提案**チェックボックスを選択します。

#### コード提案ログの表示 {#view-code-suggestions-logs}

コード提案がIDEに対して有効になっているにもかかわらず、提案がまだ表示されない場合:

1. IDEのGitLab Workflow **Extension Settings**で、**GitLab: Debug**を有効にします。
   - Web IDEの場合、[マーケットプレイス拡張機能](../../../user/project/web_ide/_index.md#manage-extensions)が有効になっている必要があります。
1. 上部のメニューで、**表示** > **Output**を選択して下部のパネルを開き、次のいずれかの操作を行います:
   - コマンドパレットで、`GitLab: Show Extension Logs`を選択します。
   - 下部のパネルの右側にあるドロップダウンリストを選択して、ログをフィルタリングします。**GitLab Workflow**を選択します。
1. GitLab Workflow **Extension Settings**で、**GitLab Duoコード提案**チェックボックスをオフにしてから再度オンにします。

### コード生成出力のストリーミングを無効にする {#disable-streaming-of-code-generation-results}

デフォルトでは、コード生成はAIが生成したコードをストリーミングします。ストリーミングは、コードスニペット全体の生成を待つのではなく、生成されたコードをエディタに段階的に送信します。これにより、よりインタラクティブで応答性の高いエクスペリエンスが可能になります。

コード生成出力が完了した場合にのみ表示したい場合は、ストリーミングをオフにできます。ストリーミングを無効にすると、コード生成リクエストの解決に時間がかかると認識される可能性があります。ストリーミングを無効にするには、次のようにします:

1. VS Codeで、上部のバーの**コード** > **設定** > **設定**に移動します。
1. 右上隅にある**Open Settings (JSON)**を選択して、`settings.json`ファイルを編集します:

   ![「設定を開く」を含む、VS Codeの右上隅にあるアイコン。](img/open_settings_v17_5.png)
1. `settings.json`ファイルで、この行を追加するか、既に存在する場合は`false`に設定します:

   ```json
   "gitlab.featureFlags.streamCodeGenerations": false,
   ```

1. 変更を保存します。

### エラー: 直接接続に失敗する {#error-direct-connection-fails}

{{< history >}}

- GitLab 17.2で直接接続が[導入](https://gitlab.com/groups/gitlab-org/-/epics/13252)されました。

{{< /history >}}

レイテンシーを削減するため、GitLab Workflow拡張機能は提案完了リクエストをGitLab Cloud Connectorに直接送信し、GitLabインスタンスをバイパスしようとします。このネットワーク接続では、VS Code拡張機能のプロキシと証明書の設定は使用されません。

GitLabインスタンスが直接接続をサポートしていない場合、またはネットワークが拡張機能のGitLab Cloud Connectorへの接続を妨げている場合は、ログに次の警告が表示されることがあります:

```plaintext
Failed to fetch direct connection details from GitLab instance.
Code suggestion requests will be sent to GitLab instance.
```

このエラーは、インスタンスが直接接続をサポートしていないか、設定が誤っていることを意味します。

このエラーが表示された場合、拡張機能はGitLab Cloud Connectorに接続できず、GitLabインスタンスを使用するように戻ります:

```plaintext
Direct connection for code suggestions failed.
Code suggestion requests will be sent to your GitLab instance.
```

GitLabインスタンスを介した間接接続は、約100ミリ秒遅くなりますが、それ以外は同じように機能します。この問題は、LANファイアウォールやプロキシ設定など、ネットワーク接続の問題が原因であることがよくあります。

## JetBrains IDEのトラブルシューティング {#jetbrains-ides-troubleshooting}

次のドキュメントは、JetBrains IDE固有のコード提案のトラブルシューティングに関するものです。

JetBrains IDEのコード提案以外のトラブルシューティングについては、[JetBrainsのトラブルシューティング](../../../editor_extensions/jetbrains_ide/jetbrains_troubleshooting.md)を参照してください。

### JetBrains IDEで提案が表示されない {#suggestions-not-displayed-in-jetbrains-ides}

1. **ツール** > **GitLab Duo**メニューから、**Verify setup**を選択します。ヘルスチェックがパスしていることを確認してください。
1. JetBrains IDEが、作業中のファイルの言語をネイティブにサポートしていることを確認してください。**設定** > **Languages & Frameworks**に移動して、JetBrains IDEでサポートされている言語とフレームワークの完全なリストを表示します。

### エラー: `unable to find valid certification path to requested target` {#error-unable-to-find-valid-certification-path-to-requested-target}

GitLab Duoプラグインは、GitLabインスタンスに接続する前に、TLS証明書の情報を検証します。[カスタムSSL証明書を追加](set_up.md#add-a-custom-certificate-for-code-suggestions)できます。

### エラー: `Failed to check token` {#error-failed-to-check-token}

このエラーは、指定された接続インスタンスのURLと、GitLab言語サーバープロセスに渡された認証トークンが無効な場合に発生します。コード提案を再度有効にするには、次のようにします:

1. IDEの上部のバーで、IDE名を選択し、次に**設定**を選択します。
1. 左側のサイドバーで、**ツール** > **GitLab Duo**を選択します。
1. **接続**で、**Verify setup**を選択します。
1. 必要に応じて、**接続**の詳細を更新します。
1. **Verify setup**を選択し、認証が成功することを確認します。
1. **OK**または**保存**を選択します。

## Microsoft Visual Studioのトラブルシューティング {#microsoft-visual-studio-troubleshooting}

次のドキュメントは、Microsoft Visual Studio固有のコード提案のトラブルシューティングに関するものです。

Microsoft Visual Studioのコード提案以外のトラブルシューティングについては、[Visual Studioのトラブルシューティング](../../../editor_extensions/visual_studio/visual_studio_troubleshooting.md)を参照してください。

### IntelliCodeが見つからない {#intellicode-is-missing}

コード提案には、Visual StudioのIntelliCodeコンポーネントが必要です。コンポーネントが見つからない場合は、Visual Studioの起動時に次のようなエラーが表示されることがあります:

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

1. Windowsのスタートメニューで、**Visual Studio Installer**を検索して開きます。
1. Visual Studioインスタンスを選択し、次に**Modify**を選択します。
1. **Individual components**タブで、**IntelliCode**を検索します。
1. コンポーネントのチェックボックスを選択し、右下の**Modify**を選択します。
1. Visual Studioインストーラーがインストールを完了するまで待ちます。

### Microsoft Visual Studioで提案が表示されない {#suggestions-not-displayed-in-microsoft-visual-studio}

1. [拡張機能を正しく設定](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension#setup)していることを確認します。
1. **ツール** > **オプション**メニューから、**GitLab**オプションを見つけます。**Log Level**が**デバッグ**に設定されていることを確認します。
1. **表示** > **Output**で、拡張機能のログを開きます。ログフィルターとして、ドロップダウンリストを**GitLab Extension**に変更します。
1. デバッグログに同様の出力が含まれていることを確認します:

```shell
14:48:21:344 GitlabProposalSource.GetCodeSuggestionAsync
14:48:21:344 LsClient.SendTextDocumentCompletionAsync("GitLab.Extension.Test\TestData.cs", 34, 0)
14:48:21:346 LS(55096): time="2023-07-17T14:48:21-05:00" level=info msg="update context"
```

別の拡張機能が同様の提案または補完機能を提供している場合、拡張機能が提案を返さない可能性があります。これを解決するには:

1. 他のすべてのVisual Studio拡張機能を無効にします。
1. コード提案を受信するようになったことを確認します。
1. 拡張機能を1つずつ再度有効にし、毎回コード提案をテストして、競合する拡張機能を見つけます。

## Neovimのトラブルシューティング {#neovim-troubleshooting}

次のドキュメントは、Neovim固有のコード提案のトラブルシューティングに関するものです。

Neovimのコード提案以外のトラブルシューティングについては、[Neovimのトラブルシューティング](../../../editor_extensions/neovim/neovim_troubleshooting.md)を参照してください。

### コード補完が失敗する {#code-completions-fails}

1. `omnifunc`がNeovimで設定されていることを確認します:

   ```lua
   :verbose set omnifunc?
   ```

1. 次のコマンドをNeovimで実行して、言語サーバーがアクティブであることを確認します:

   ```lua
   :lua =vim.lsp.get_active_clients()
   ```

1. `~/.local/state/nvim/lsp.log`の言語サーバーのログを確認します。
1. Neovimでこのコマンドを実行して、エラーの`vim.lsp`ログパスを調べます:

   ```lua
   :lua =vim.cmd('view ' .. vim.lsp.get_log_path())
   ```

## コード補完のレイテンシーの問題 {#latency-issues-with-code-completion}

コード補完用に特定のモデルが選択されたプロジェクトにシートが割り当てられている場合:

- IDE拡張機能は、[AIゲートウェイへの直接接続](../../../administration/gitlab_duo/gateway.md#region-support)を無効にします
- コード補完リクエストはGitLabモノリスを経由し、次に指定されたモデルを選択して、これらのリクエストに応答します。

これにより、コード補完リクエストのレイテンシーが増加する可能性があります。
