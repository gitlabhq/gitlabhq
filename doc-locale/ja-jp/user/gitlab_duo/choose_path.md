---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Duo AIネイティブ機能を使用してソフトウェア開発ライフサイクルを強化する方法について説明します。
title: 'GitLab Duo: パスを選択する'
---

GitLab Duoは、GitLabでの作業を支援するAIネイティブな機能スイートです。

実行したいことに最も適したパスを選択します:

{{< tabs >}}

{{< tab title="はじめに" >}}

**最適な対象**: GitLab Duoを初めて使うユーザー

このパスでは以下を学びます:

- さまざまなGitLab Duo機能を使用する
- GitLab Duo ChatでAIのサポートを受ける
- コードを生成および改善する

[ここから始める: GitLab Duo →](_index.md)

{{< /tab >}}

{{< tab title="コーディングを強化する" >}}

**最適な対象**: 生産性向上を目指すデベロッパー

このパスでは以下を学びます:

- IDEでコード提案を使用する
- コードを生成、理解、リファクタリングする
- テストを自動作成する

[ここから始める: コード提案 →](../project/repository/code_suggestions/_index.md)

{{< /tab >}}

{{< tab title="コードレビューを改善する" >}}

**最適な対象**: レビュアーとチームリーダー

このパスでは以下を学びます:

- マージリクエストの説明を生成する
- AIネイティブのコードレビューを取得する
- レビューコメントを要約してコミットメッセージを生成する

[ここから始める: マージリクエストでのGitLab Duo →](../project/merge_requests/duo_in_merge_requests.md)

{{< /tab >}}

{{< tab title="アプリケーションを保護する" >}}

**最適な対象**: セキュリティおよびDevSecOpsの専門家

このパスでは以下を学びます:

- 脆弱性を理解する
- 修正候補を自動生成する
- セキュリティ問題に対処するマージリクエストを作成する

[ここから始める: 脆弱性の説明と修正 →](../application_security/vulnerabilities/_index.md#vulnerability-explanation)

{{< /tab >}}

{{< /tabs >}}

## クイックスタート {#quick-start}

今すぐGitLab Duoを使い始めたいですか？手順は次のとおりです:

1. GitLab UIの右上隅、**GitLab Duo Chat**を選択するか、IDEでGitLab Duo Chatを開きます。
1. プロジェクト、コード、またはGitLabの使用方法に関する質問をします。
1. IDEでコード提案などのAIネイティブ機能を試すか、Chatを使用します:

   - UIで、大量の情報を含むイシューを要約します。
   - IDEで、既存のコードをリファクタリングします。

[GitLab Duoの可能性をすべて表示 →](_index.md)

## 一般的なタスク {#common-tasks}

特定の作業が必要ですか？一般的なタスクをいくつか紹介します:

| タスク | 説明 | クイックガイド |
|------|-------------|-------------|
| AI支援を受ける | コード、プロジェクト、またはGitLabについてGitLab Duoに質問する | [GitLab Duo Chat →](../gitlab_duo_chat/_index.md) |
| コードを生成する | IDEで入力中にコード提案を取得する | [コード提案 →](../project/repository/code_suggestions/_index.md) |
| コードを理解する | コードを平易な言葉で説明してもらう | [コードの説明 →](../project/repository/code_explain.md) |
| CI/CDの問題を修正する | 失敗したジョブを分析して修正する | [根本原因分析 →](../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) |
| 変更を要約する | マージリクエストの説明を生成する | [マージリクエストサマリー →](../project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes) |

## GitLab Duoがワークフローとどのように統合されているか {#how-gitlab-duo-integrates-with-your-workflow}

GitLab Duoは開発プロセスと統合されており、以下で使用できます:

- GitLab UI内
- GitLab Duo Chat経由
- IDE拡張機能
- CLI

## 経験レベル {#experience-levels}

### 初心者向け {#for-beginners}

GitLab Duoが初めての場合は、次の機能から始めましょう:

- **[GitLab Duo Chat](../gitlab_duo_chat/_index.md)** \- GitLabについて質問し、基本的なタスクでヘルプを得る
- **[コード提案](../project/repository/code_suggestions/_index.md)** \- IDEでAIネイティブのコード補完を取得する
- **[コードの説明](../project/repository/code_explain.md)** \- ファイルやマージリクエスト内のコードを理解する
- **[マージリクエストサマリー](../project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes)** \- 変更の説明を自動生成する

### 中級ユーザー向け {#for-intermediate-users}

基本に慣れたら、これらのより高度な機能を試してみましょう:

- **[テストの生成](../gitlab_duo_chat/examples.md#write-tests-in-the-ide)** \- コードのテストを自動作成する
- **[根本原因分析](../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)** \- 失敗したCI/CDジョブのトラブルシューティングを行う

### 上級ユーザー向け {#for-advanced-users}

GitLab Duoで生産性を最大限に高める準備ができたら:

- **[GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md)** \- 独自のインフラストラクチャでLLMをホストする
- **[GitLab Duo Agent Platform](../duo_agent_platform/_index.md)** \- 開発ワークフローのタスクを自動化する
- **[脆弱性の修正](../application_security/vulnerabilities/_index.md#vulnerability-resolution)** \- セキュリティ問題を修正するマージリクエストを自動生成する

## ベストプラクティス {#best-practices}

GitLab Duoを効果的に使用するためのヒントを次に示します:

1. **プロンプトで具体的にする**
   - より良い結果を得るために、明確なコンテキストを提供する
   - コードと目標に関する関連情報を含める
   - Chatでコードタスクコマンド（`/explain`、`/refactor`、`/tests`など）を使用する

1. **責任を持ってコードを改善する**
   - AIが生成したコードは、使用する前に必ずレビューする
   - 生成されたコードをテストして、期待どおりに動作することを確認する
   - 適切なレビューを行った上で脆弱性の解決を使用する

1. **反復的に改良する**
   - 応答が役に立たない場合は、質問を絞り込む
   - 複雑なリクエストは分割して聞く
   - コンテキストを改善するために、詳細を追加する

1. **学習のためにChatを活用する**
   - よくわからないGitLab機能について質問する
   - エラーメッセージと問題の説明を入手する
   - 特定のテクノロジーのベストプラクティスを学ぶ

## 次の手順 {#next-steps}

さらに詳しく知りたいですか？これらのリソースを試してください:

- [GitLab Duoのユースケース](use_cases.md) \- 実用的な例と演習
- [GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md) \- データを完全に管理する

## トラブルシューティング {#troubleshooting}

問題が発生していますか？次の一般的な解決策を確認してください:

- [GitLab Duo機能がセルフマネージド環境で動作しない](troubleshooting.md#gitlab-duo-features-do-not-work-on-self-managed)
- [ユーザーがGitLab Duo機能を使用できない](troubleshooting.md#gitlab-duo-features-not-available-for-users)
- [ヘルスチェックを実行](../../administration/gitlab_duo/setup.md#run-a-health-check-for-gitlab-duo)して、GitLab Duoの設定を診断する

さらにヘルプが必要ですか？GitLabドキュメントを検索するか、[GitLabコミュニティに質問](https://forum.gitlab.com/)してください。
