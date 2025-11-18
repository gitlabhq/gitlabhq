---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: ライフサイクル全体でAIネイティブなアシスタントを活用しましょう。
title: GitLab Duoのスタートガイド
---

GitLab Duoは、AIネイティブなアシスタントです。コードの作成、レビュー、編集をはじめ、GitLabのワークフロー全体にわたってさまざまなタスクを支援します。パイプラインのトラブルシューティング、テストの作成、脆弱性への対応などにも役立ちます。

## ステップ1: GitLab Duoにアクセスできることを確認する {#step-1-ensure-you-have-access-to-gitlab-duo}

GitLab Duoを利用するには、組織がPremiumまたはUltimateサブスクリプションを契約し、GitLab Duoアドオンを導入している必要があります。

導入しているアドオンによって、アクセスできるGitLab Duoの機能は異なります。

- GitLab Duo Coreアドオンは、すべてのPremiumおよびUltimateのサブスクリプションに付属しています。
- GitLab Duo ProおよびGitLab Duo Enterpriseアドオンは、購入可能です。

GitLab Duoの機能を利用する際、組織はGitLabが提供するデフォルトの言語モデルを使用するか、GitLab Duo Self-Hostedを使用して独自のモデルをホストできます。

GitLab Duoの機能にアクセスする際に問題が発生した場合は、管理者がインストールのヘルスチェックを実行できます。

詳細については、以下を参照してください。

- [アドオン別のGitLab Duoの機能](../gitlab_duo/feature_summary.md)。
- [アドオンの購入方法](../../subscriptions/subscription-add-ons.md)。
- [GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md)。
- [ヘルスチェックの詳細](../../administration/gitlab_duo/setup.md#run-a-health-check-for-gitlab-duo)。

## ステップ2: UIでGitLab Duo Chatを試す {#step-2-try-gitlab-duo-chat-in-the-ui}

次に、GitLab UIでチャットを使ってみましょう。

プロジェクトに移動すると、右上隅に**GitLab Duo Chat**というボタンが表示されているはずです。このボタンが使用可能な場合、すべてが正しく設定されていることを意味します。チャットで質問するか、`/`と入力してスラッシュコマンドのリストを表示してみてください。

詳細については、以下を参照してください。

- [GitLab Duo Chat](../gitlab_duo_chat/_index.md)。

## ステップ3: その他のGitLab Duo機能を試す {#step-3-try-other-gitlab-duo-features}

GitLab Duoは、ワークフローのあらゆるステージで使用できます。CI/CDパイプラインのトラブルシューティングからテストケースの作成、セキュリティの脅威の解決まで、GitLab Duoはさまざまな形で支援します。

アクセスできる機能は、契約しているサブスクリプションのプラン、アドオン、および提供形態によって異なります。

次に例を示します。

- 根本原因分析にアクセスできる場合、失敗したCI/CDジョブのいずれかに移動し、ページの下部にある**トラブルシューティングを行う**を選択します。

- ディスカッションサマリーにアクセスできる場合、コメントが多いイシューの**アクティビティー**セクションで、**サマリーを表示**を選択します。GitLab Duoがイシューの内容を要約します。

詳細については、以下を参照してください。

- [GitLab Duoの機能の全一覧](../gitlab_duo/_index.md)。
- [開発中のGitLab Duoの機能を有効にする](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features)。

## ステップ4: IDEでGitLab Duoを使用する準備を行う {#step-4-prepare-to-use-gitlab-duo-in-your-ide}

これで、GitLab Duo Chatやコード提案など、GitLab Duoの機能をIDEで試すことができます。

IDEでGitLab Duo Chatを使用するには、拡張機能をインストールし、GitLabに対して認証する必要があります。

- GitLab 17.11以前では、GitLab Duo ProまたはEnterpriseアドオンが必要です。
- 18.0以降では、GitLab Duoを有効にし、GitLab Duo Core、Pro、またはEnterpriseアドオンを導入する必要があります。GitLab Duo Coreは、すべてのPremiumおよびUltimateのサブスクリプションに含まれています。

また、GitLab Duo ProまたはEnterpriseを利用している場合は、Web IDEを使用することもできます。これはGitLab UIに含まれており、すでに設定が完了しています。

詳細については、以下を参照してください。

- [GitLab Duoを有効にする](../gitlab_duo/turn_on_off.md)。
- [VS Code用拡張機能を設定する](../../editor_extensions/visual_studio_code/setup.md)。
- [JetBrains用拡張機能を設定する](../../editor_extensions/jetbrains_ide/setup.md)。
- [Visual Studio用拡張機能を設定する](../../editor_extensions/visual_studio/setup.md)。
- [Neovim用拡張機能を設定する](../../editor_extensions/neovim/setup.md)。
- [Web IDEを使用する](../project/web_ide/_index.md)。

## ステップ5: IDEでコード提案とチャットの使用を開始する {#step-5-start-using-code-suggestions-and-chat-in-your-ide}

最後に、IDEでコード提案とチャットを試してみましょう。

- コード提案は、入力中にコードを推奨します。
- チャットは、コードやその他の必要な情報について質問するために使用します。

提案を受けたい言語を選択できます。

詳細については、以下を参照してください。

- [サポートされる拡張機能と言語](../project/repository/code_suggestions/supported_extensions.md)。
- [コード提案を有効にする](../project/repository/code_suggestions/set_up.md#turn-on-code-suggestions)。
- [VS Code用GitLab Workflow拡張機能のトラブルシューティング](../../editor_extensions/visual_studio_code/troubleshooting.md)。
- [JetBrains IDE用GitLabプラグインのトラブルシューティング](../../editor_extensions/jetbrains_ide/jetbrains_troubleshooting.md)。
- [Visual Studio用GitLab拡張機能のトラブルシューティング](../../editor_extensions/visual_studio/visual_studio_troubleshooting.md)。
- [Neovim用GitLabプラグインのトラブルシューティング](../../editor_extensions/neovim/neovim_troubleshooting.md)。
