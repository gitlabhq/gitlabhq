---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab for VS Code拡張機能を使用して、GitLabの一般的なタスクをVS Codeで直接処理します。
title: GitLab for VS Code拡張機能
---

[GitLab for VS Code拡張機能](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)は、GitLab Duoやその他のGitLab機能をIDEに直接統合します。

利用を開始するには、[拡張機能をインストールして設定](setup.md)します。セキュリティを強化するために、Visual Studio Code開発コンテナに拡張機能を設定できます。

設定が完了すると、この拡張機能により、日常的に使用するGitLabの機能がVS Code環境に直接組み込まれます。

- [プロジェクトで作業する](projects.md): イシューを使用して作業を計画および追跡し、マージリクエストで変更をレビューおよび議論し、コードスニペットを共有します。AIネイティブな計画とコーディングにはGitLab Duoを使用します。
- [CI/CDパイプラインを監視およびテストする](cicd.md): パイプラインの設定をテストします。パイプラインのステータスとジョブ出力を表示します。
- [アプリケーションを保護する](security_scanning.md): セキュリティの調査結果をレビューし、プロジェクトのSASTスキャンを実行します。
- [リポジトリを参照する](remote_urls.md#browse-a-repository-in-read-only-mode): GitLabリポジトリをクローンせずに読み取り専用モードでアクセスします。

VS CodeでGitLabプロジェクトを表示すると、拡張機能は現在のブランチに関する情報を表示します。

- ブランチの最新のCI/CDパイプラインのステータス。
- このブランチのマージリクエストへのリンク。
- マージリクエストに[イシューのクローズパターン](../../user/project/issues/managing_issues.md#closing-issues-automatically)が含まれている場合は、そのイシューへのリンク。

## GitLab拡張機能パネル {#gitlab-extension-panels}

拡張機能には次の機能が含まれています:

- 左サイドバーの**GitLab**（{{< icon name="tanuki" >}}）: イシューとマージリクエストを管理し、CI/CDコマンドを実行し、パイプラインステータスを表示し、セキュリティスキャンを実行します。[カスタムクエリ](custom_queries.md)でビューを拡張することもできます。
- 左サイドバーの**GitLab Duo Agent Platform**（{{< icon name="duo-agentic-chat" >}}）:
  - チャットタブ: GitLab Duo Agentic Chatを操作するか、**新しいチャット**（{{< icon name="duo-chat-new" >}}）ドロップダウンリストを使用して、基礎エージェントまたはカスタムエージェントを選択して作業します。
  - フロータブ: ソフトウェア開発フローを使用します。チャットとフローの[違い](../../user/duo_agent_platform/flows/foundational_flows/software_development.md#flow-and-chat-comparison)について詳しく知る。
- ステータスバーの**Duo**（{{< icon name="tanuki-ai" >}}）: GitLab Duoコード提案の機能ステータスを確認し、コードを作成しながらファイル内の提案をレビューします。
- 左サイドバーの**GitLab Duo Chat**（{{< icon name="duo-chat" >}}）: GitLab Duo Non-Agentic Chatを操作します。

これらの機能が表示されない場合は、[トラブルシューティング](troubleshooting.md#gitlab-duo-features-are-unavailable)を参照してください。

## キーボードショートカットをカスタマイズする {#customize-keyboard-shortcuts}

**Accept Inline Suggestion**（インライン提案を受け入れる）、**Accept Next Word Of Inline Suggestion**（インライン提案の次の単語を受け入れる）、または**Accept Next Line Of Inline Suggestion**（インライン提案の次の行を受け入れる）に対して、別のキーボードショートカットを割り当てることができます。

1. VS Codeで`Preferences: Open Keyboard Shortcuts`コマンドを実行します。
1. 編集するショートカットを見つけて、**Change keybinding**（キー割り当てを変更）（{{< icon name="pencil" >}}）を選択します。
1. 使用するショートカットを**Accept Inline Suggestion**インライン提案を受け入れる）、**Accept Next Word Of Inline Suggestion**（インライン提案の次の単語を受け入れる）、または**Accept Next Line Of Inline Suggestion**（インライン提案の次の行を受け入れる）に割り当てます。
1. <kbd>Enter</kbd>キーを押して変更を保存します。

## 拡張機能を更新する {#update-the-extension}

拡張機能を最新バージョンに更新するには、次の手順に従います。

1. Visual Studio Codeで、**設定** > **Extensions**に移動します。
1. **GitLab（`gitlab.com`）**が発行した**GitLab**を検索します。
1. **Extension: GitLab**から、**Update to {later version}**を選択します。
1. オプション。今後自動更新を有効にするには、**Auto-Update**を選択します。

## プレリリースバージョンをインストールする {#install-the-pre-release-version}

GitLabは、拡張機能のプレリリースビルドをVS Code拡張機能マーケットプレースに公開しています。

プレリリースビルドをインストールするには:

1. VS Codeを開きます。
1. **Extensions** > **GitLab**で、**Switch to Pre-release Version**を選択します。
1. **Restart Extensions**を選択します。

## GitLab Duoのステータスを確認 {#check-gitlab-duo-status}

1. Visual Studio Codeの画面下部のステータスバーで、GitLabアイコン（{{< icon name="tanuki" >}}）を選択します。
1. VS Codeの検索ボックスの下にメニューが開き、GitLab for VS Code拡張機能がステータスを表示します。エラーがある場合は**Status:**の横に表示されます。

GitLab Duo Non-Agentic Chatの場合は、チャットの[ステータス](../../user/gitlab_duo_chat/_index.md#check-the-status-of-chat)も確認できます。

## 関連トピック {#related-topics}

- [GitLab for VS Codeのリリース](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/releases)
- [エディタ拡張機能のセキュリティに関する考慮事項](../security_considerations.md)
- [コマンドパレットコマンド](settings.md#command-palette-commands)
- [GitLab for VS Code拡張機能のトラブルシューティング](troubleshooting.md)
- [GitLab for VS Code拡張機能をダウンロード](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)
- 拡張機能の[ソースコード](https://gitlab.com/gitlab-org/gitlab-vscode-extension/)
- [GitLab言語サーバードキュメント](../language_server/_index.md)
