---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: コード提案の一般的な問題に関するトラブルシューティングのヒント。
title: コード提案のトラブルシューティング
---

GitLab Duoコード提案を使用する際に、以下の問題が発生する可能性があります。

インスタンスがコード提案を実行するための要件を満たしているかどうかをテストするには、[ヘルスチェック](../../../gitlab_duo/turn_on_off.md)を実行します。

GitLab Duoのトラブルシューティングの詳細については、以下を参照してください:

- [GitLab Duoのトラブルシューティング](../../../gitlab_duo/troubleshooting.md)。
- [GitLab Duo Chatのトラブルシューティング](../../../gitlab_duo_chat/troubleshooting.md)。
- [GitLab Duo Self-Hostedのトラブルシューティング](../../../../administration/gitlab_duo_self_hosted/troubleshooting.md)。

## 提案が表示されない {#suggestions-are-not-displayed}

提案が表示されない場合は、以下を確認してください:

- [GitLab Duo](../../../gitlab_duo/turn_on_off.md)が正しく設定されていることを確認してください。
- [サポートされている言語](supported_extensions.md#supported-languages-by-ide)と[エディタ拡張機能](supported_extensions.md#supported-editor-extensions)を使用していることを確認してください。
- [エディタ拡張機能が正しく設定されている](set_up.md#configure-editor-extension)ことを確認してください。

それでも提案が表示されない場合は、異なるIDEについて、次のトラブルシューティング手順を試してください:

- [VS CodeまたはGitLab Web IDE](#suggestions-not-displayed-in-vs-code-or-gitlab-web-ide)
- [JetBrains IDE](#suggestions-not-displayed-in-jetbrains-ides)
- [Microsoft Visual Studio](#suggestions-not-displayed-in-microsoft-visual-studio)

## コード提案が401エラーを返す {#code-suggestions-returns-a-401-error}

コード提案は、GitLabとの[サブスクリプションを同期](../../../../administration/license.md)するトークンに依存しています。

トークンの有効期限が切れると、コード提案はステータス`401`で次のエラーを返します:

```plaintext
Token validation failed in Language Server:
(Failed to check token: Error: Fetching Information about personal access token
```

GitLabがクラウドサーバーにアクセスできる場合は、[ライセンスの手動同期](../../../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data)を試してください。

## 認証のトラブルシューティング {#authentication-troubleshooting}

この問題は、認証の最近の変更、特にトークンシステムに起因する可能性があります。この問題を解決するには、以下の手順に従います:

1. 既存のパーソナルアクセストークンをGitLabアカウントの設定から削除します。
1. OAuthを使用してGitLabアカウントを再認可します。
1. さまざまなファイル拡張子でコード提案機能をテストし、問題が解決されたかどうかを確認します。

## エラー422: デフォルトのGitLab Duoネームスペースが設定されていない {#error-422-no-default-gitlab-duo-namespace}

`Code Suggestions cannot detect a namespace for this project. To continue, please set a default GitLab Duo namespace in your user preferences.`というエラーが表示されることがあります。

このイシューは、複数のGitLab Duoネームスペースに属している場合、またはGitLabリモートが設定されていないプロジェクトをローカルで作業している場合に発生します。

これを解決するには、[デフォルトのGitLab Duoネームスペースを設定](../../../profile/preferences.md#set-a-default-gitlab-duo-namespace)します。

## VS Codeのトラブルシューティング {#vs-code-troubleshooting}

次のドキュメントは、VS Code固有のコード提案のトラブルシューティングに関するものです。

その他のGitLab for VS Codeのトラブルシューティングについては、[GitLab for VS Code拡張機能のトラブルシューティング](../../../../editor_extensions/visual_studio_code/troubleshooting.md)を参照してください。

### VS CodeまたはGitLab Web IDEで提案が表示されない {#suggestions-not-displayed-in-vs-code-or-gitlab-web-ide}

GitLab Self-Managedを使用している場合は、[GitLab Web IDE](../../web_ide/_index.md)のコード提案が有効になっていることを確認してください。ローカルIDEとして、同じ設定がVS Codeに適用されます。

1. IDEで、設定エディタを開きます:
   - macOSでは、<kbd>Command</kbd>+<kbd>,</kbd>を押してください。
   - WindowsまたはLinuxでは、<kbd>Control</kbd>+<kbd>,</kbd>を押してください。
1. **GitLab Duo**の設定に移動します:
   - VS Codeで、**Extensions** > **GitLab** > **GitLab Duo**を選択します。
   - GitLab Web IDEで、**Extensions** > **GitLab Workflow** > **GitLab Duo**を選択します。
1. **GitLab › Duo Code Suggestions: 有効**にチェックボックスを選択します。

#### コード提案ログを表示する {#view-code-suggestions-logs}

コード提案がIDEに対して有効になっているにもかかわらず提案がまだ表示されない場合、以下の手順に従います:

1. IDEで、設定エディタを開きます:
   - macOSでは、<kbd>Command</kbd>+<kbd>,</kbd>を押してください。
   - WindowsまたはLinuxでは、<kbd>Control</kbd>+<kbd>,</kbd>を押してください。
1. **その他**の設定に移動します:
   - VS Codeで、**Extensions** > **GitLab** > **その他**を選択します。
   - GitLab Web IDEで、**Extensions** > **GitLab Workflow** > **その他**を選択します。
1. **GitLab: Debug**で、チェックボックスをオンにします。
   - Web IDEの場合、[マーケットプレイス拡張機能](../../web_ide/_index.md#manage-extensions)が有効になっている必要があります。
1. 上部のメニューで、**View** > **Output**を選択して下部のパネルを開き、次のいずれかの操作を行います:
   - コマンドパレットで、`GitLab: Show Extension Logs`を選択します。
   - 下部のパネルの右側にあるドロップダウンリストを選択して、ログをフィルタリングします。**GitLab**を選択します。
1. 設定エディタで、**GitLab Duo**の設定に移動します。
1. **GitLab Duoコード提案**チェックボックスの選択を解除して再度選択します。

### コード生成出力のストリーミングを無効にする {#disable-streaming-of-code-generation-results}

デフォルトでは、コード生成はAIが生成したコードをストリーミングします。ストリーミングは、コードスニペット全体の生成を待つのではなく、生成されたコードを逐次エディタに送信します。これにより、よりインタラクティブで応答性の高いエクスペリエンスが可能になります。

コード生成出力が完了した場合にのみ表示したい場合は、ストリーミングをオフにできます。ストリーミングを無効にすると、コード生成リクエストの解決に時間がかかるように感じられる場合があります。ストリーミングを無効にするには、次の手順に従います:

1. VS Codeで、設定エディタを開きます:
   - macOSでは、<kbd>Command</kbd>+<kbd>,</kbd>を押してください。
   - WindowsまたはLinuxでは、<kbd>Control</kbd>+<kbd>,</kbd>を押してください。
1. 右上隅にある**Open Settings（JSON）**を選択して、`settings.json`ファイルを編集します:

   ![「Open Settings」が表示された、VS Codeの右上隅にあるアイコン。](img/open_settings_v17_5.png)
1. `settings.json`ファイルに次の行を追加するか、すでに存在する場合は`false`に設定します:

   ```json
   "gitlab.featureFlags.streamCodeGenerations": false,
   ```

1. 変更を保存します。

### エラー: 直接接続に失敗する {#error-direct-connection-fails}

{{< history >}}

- GitLab 17.2で直接接続が[導入](https://gitlab.com/groups/gitlab-org/-/epics/13252)されました。

{{< /history >}}

レイテンシーを削減するため、GitLab for VS Code拡張機能は提案完了リクエストをGitLab Cloud Connectorに直接送信し、GitLabインスタンスをバイパスしようとします。このネットワーク接続では、VS Code拡張機能のプロキシと証明書の設定は使用されません。

GitLabインスタンスが直接接続をサポートしていない場合、またはネットワークによって拡張機能がGitLab Cloud Connectorに接続できない場合は、ログに次の警告が表示されることがあります:

```plaintext
Failed to fetch direct connection details from GitLab instance.
Code suggestion requests will be sent to GitLab instance.
```

このエラーは、インスタンスが直接接続をサポートしていないか、設定が誤っていることを意味します。

次のエラーが表示された場合、拡張機能はGitLab Cloud Connectorに接続できず、GitLabインスタンス経由にリバートします:

```plaintext
Direct connection for code suggestions failed.
Code suggestion requests will be sent to your GitLab instance.
```

GitLabインスタンス経由の間接接続は約100ミリ秒遅くなりますが、それ以外は同じように機能します。この問題は多くの場合、LANファイアウォールやプロキシ設定など、ネットワーク接続の問題が原因で発生します。

## JetBrains IDEのトラブルシューティング {#jetbrains-ides-troubleshooting}

次のドキュメントは、JetBrains IDE固有のコード提案のトラブルシューティングに関するものです。

JetBrains IDEのコード提案以外のトラブルシューティングについては、[JetBrainsのトラブルシューティング](../../../../editor_extensions/jetbrains_ide/jetbrains_troubleshooting.md)を参照してください。

### JetBrains IDEで提案が表示されない {#suggestions-not-displayed-in-jetbrains-ides}

1. **Tools** > **GitLab Duo**メニューから、**Verify setup**を選択します。ヘルスチェックに合格することを確認してください。
1. JetBrains IDEが、作業中のファイルの言語をネイティブにサポートしていることを確認してください。**Settings** > **Languages & Frameworks**に移動して、JetBrains IDEでサポートされている言語とフレームワークの完全なリストを確認します。

### エラー: `unable to find valid certification path to requested target` {#error-unable-to-find-valid-certification-path-to-requested-target}

GitLab Duoプラグインは、GitLabインスタンスに接続する前にTLS証明書情報を検証します。[カスタムSSL証明書を追加](set_up.md#add-a-custom-certificate-for-code-suggestions)できます。

### エラー: `Failed to check token` {#error-failed-to-check-token}

このエラーは、指定された接続インスタンスURLや、GitLab言語サーバープロセスに渡された認証トークンが無効な場合に発生します。コード提案を再度有効にするには、次の手順に従います:

1. お使いのIDEで、トップバーにあるIDEの名前を選択し、次に**設定**を選択します。
1. 左サイドバーで、**ツール** > **GitLab Duo**を選択します。
1. **Connection**で、**Verify setup**を選択します。
1. 必要に応じて、**Connection**の詳細を更新します。
1. **Verify setup**を選択し、認証が成功することを確認します。
1. **OK**または**Save**を選択します。

## Microsoft Visual Studioのトラブルシューティング {#microsoft-visual-studio-troubleshooting}

次のドキュメントは、Microsoft Visual Studio固有のコード提案のトラブルシューティングに関するものです。

Microsoft Visual Studioのコード提案以外のトラブルシューティングについては、[Visual Studioのトラブルシューティング](../../../../editor_extensions/visual_studio/visual_studio_troubleshooting.md)を参照してください。

### IntelliCodeがない {#intellicode-is-missing}

コード提案には、Visual StudioのIntelliCodeコンポーネントが必要です。このコンポーネントがない場合は、Visual Studioの起動時に次のようなエラーが表示されることがあります:

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
1. **Tools** > **Options**メニューから、**GitLab**オプションを見つけます。**Log Level**が**Debug**に設定されていることを確認します。
1. **View** > **Output**で、拡張機能のログを開きます。ログフィルターとして、ドロップダウンリストを**GitLab Extension**に変更します。
1. デバッグログに同様の出力が含まれていることを確認します:

```shell
14:48:21:344 GitlabProposalSource.GetCodeSuggestionAsync
14:48:21:344 LsClient.SendTextDocumentCompletionAsync("GitLab.Extension.Test\TestData.cs", 34, 0)
14:48:21:346 LS(55096): time="2023-07-17T14:48:21-05:00" level=info msg="update context"
```

別の拡張機能が同様の提案または補完機能を提供している場合、拡張機能が提案を返さない可能性があります。これを解決するには、次の手順に従います:

1. 他のすべてのVisual Studio拡張機能を無効にします。
1. コード提案を受け取れるようになったことを確認します。
1. 拡張機能を1つずつ再度有効にし、毎回コード提案をテストして、競合する拡張機能を見つけます。

## Neovimのトラブルシューティング {#neovim-troubleshooting}

次のドキュメントは、Neovim固有のコード提案のトラブルシューティングに関するものです。

Neovimのコード提案以外のトラブルシューティングについては、[Neovimのトラブルシューティング](../../../../editor_extensions/neovim/neovim_troubleshooting.md)を参照してください。

### コード補完が失敗する {#code-completions-fails}

1. Neovimで`omnifunc`が設定されていることを確認します:

   ```lua
   :verbose set omnifunc?
   ```

1. Neovimで次のコマンドを実行して、言語サーバーがアクティブであることを確認します:

   ```lua
   :lua =vim.lsp.get_active_clients()
   ```

1. `~/.local/state/nvim/lsp.log`で言語サーバーのログを確認します。
1. Neovimで次のコマンドを実行して、`vim.lsp`のログパスにエラーがないか確認します:

   ```lua
   :lua =vim.cmd('view ' .. vim.lsp.get_log_path())
   ```

## コード補完のレイテンシーの問題 {#latency-issues-with-code-completion}

コード補完用に特定のモデルが選択されたプロジェクトにシートが割り当てられている場合、以下のようになります:

- IDE拡張機能が[AIゲートウェイへの直接接続](../../../../administration/gitlab_duo/gateway.md#region-support)を無効にします。
- コード補完リクエストはGitLabモノリスを経由し、次に指定されたモデルを選択して、これらのリクエストに応答します。

これにより、コード補完リクエストのレイテンシーが増加する可能性があります。
