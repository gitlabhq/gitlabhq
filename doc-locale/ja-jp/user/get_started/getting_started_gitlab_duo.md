---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: AIネイティブな機能を開発ライフサイクル全体で利用します。
title: GitLab Duo（Classic）を使い始める
---

GitLab Duoは、プランニング、開発、セキュリティのワークフロー全体を支援するAIネイティブなアシスタントです。GitLab Duo（Classic）には、コード提案やコードの説明のような機能が含まれており、コードの記述、レビュー、編集を支援します。

## ステップ1: GitLab Duoにアクセスできることを確認する {#step-1-ensure-you-have-access-to-gitlab-duo}

GitLab Duoには、管理者、グループ、またはプロジェクトオーナーによるセットアップが必要です。

GitLab Duoの機能にアクセスする際に問題が発生した場合は、管理者がインストールのヘルスチェックを実行できます。

詳細については、以下を参照してください: 

- [GitLab Duoを有効にする](../gitlab_duo/turn_on_off.md)。
- [ヘルスチェックの詳細](../../administration/gitlab_duo/configure/gitlab_self_managed.md#run-a-health-check-for-gitlab-duo)。

## ステップ2: UIでGitLab Duo Chatを試す {#step-2-try-gitlab-duo-chat-in-the-ui}

開始するには、GitLabUIでChatを使用してみてください。

プロジェクトに移動し、右上隅にある**GitLab Duo Chat**ボタンを選択してください。このボタンが使用可能な場合、すべてが正しく設定されていることを意味します。特定のイシューやマージリクエスト、または一般的なGitLabについてChatに質問してみてください。

詳細については、以下を参照してください: 

- [GitLab Duo Chat（Classic）](../gitlab_duo_chat/_index.md)。

## ステップ3: その他のGitLab Duo機能を試す {#step-3-try-other-gitlab-duo-features}

GitLab Duoは、ワークフロー全体で利用できます。スプリントの計画からトラブルシューティングCI/CDパイプラインまで、テストケースの作成からセキュリティ脅威の解決まで、GitLab Duoはさまざまな方法であなたを支援できます。

アクセスできる機能は、サブスクリプションによって異なる場合があります。

詳細については、以下を参照してください: 

- [GitLab Duo機能がワークフローに合致するかどうかを判断するのに役立つ意思決定ツリー](../gitlab_duo/_index.md)。
- [GitLab Duo（Classic）機能の完全なリスト](../gitlab_duo/feature_summary.md)。
- [開発中のGitLab Duo機能を有効にする方法](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features)。

## ステップ4: IDEでGitLab Duoを使用する準備を行う {#step-4-prepare-to-use-gitlab-duo-in-your-ide}

次に、IDEでGitLab Duo機能を試してください。VS Codeやその他のエディタでは、GitLab Duo Chat、ソフトウェア開発フロー、コード提案などの機能を使用できます。

開始するには、拡張機能をインストールし、GitLabで認証する必要があります。

詳細については、以下を参照してください: 

- [VS Code用拡張機能を設定する](../../editor_extensions/visual_studio_code/setup.md)。
- [JetBrains用拡張機能を設定する](../../editor_extensions/jetbrains_ide/setup.md)。
- [Visual Studio用拡張機能を設定する](../../editor_extensions/visual_studio/setup.md)。
- [Neovim用拡張機能を設定する](../../editor_extensions/neovim/setup.md)。
- [Web IDEを使用する](../project/web_ide/_index.md)。

## ステップ5: IDE機能の使用を開始する {#step-5-start-using-ide-features}

最後に、IDEでGitLab Duoをテストします。

- コード提案は、入力中にコードを推奨します。
- チャットは、コードやその他の必要な情報について質問するために使用します。
- ソフトウェア開発フローは、あなたに代わってタスクを実行します。

提案を希望する開発言語を選択できます。

詳細については、以下を参照してください: 

- [サポートされる拡張機能と言語](../project/repository/code_suggestions/supported_extensions.md)。
- [コード提案（Classic）を有効にする](../project/repository/code_suggestions/set_up.md#turn-on-code-suggestions)。
- [GitLab for VS Code拡張機能のトラブルシューティング](../../editor_extensions/visual_studio_code/troubleshooting.md)。
- [JetBrains IDE用GitLabプラグインのトラブルシューティング](../../editor_extensions/jetbrains_ide/jetbrains_troubleshooting.md)。
- [Visual Studio のGitLabに関するトラブルシューティング](../../editor_extensions/visual_studio/visual_studio_troubleshooting.md)。
- [Neovim用GitLabプラグインのトラブルシューティング](../../editor_extensions/neovim/neovim_troubleshooting.md)。
