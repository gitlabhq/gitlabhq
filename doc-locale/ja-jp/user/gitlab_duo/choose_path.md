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

{{< tab title="始めましょう" >}}

**Perfect for**（おすすめ）: GitLab Duoを調査する新しいユーザー

このパスに従って、次の方法を学習します:

- さまざまなGitLab Duo機能を使用する
- AIからGitLab Duo Chatを通じて支援を受ける
- コードを生成および改善する

[開始場所: GitLab Duo →](_index.md)

{{< /tab >}}

{{< tab title="コーディングを強化" >}}

**Perfect for**（おすすめ）: 生産性の向上を目指すデベロッパー

このパスに従って、次の方法を学習します:

- IDEでコード提案を使用する
- コードを生成、理解、リファクタリングする
- 自動的にテストを作成する

[開始場所: コード提案 →](../project/repository/code_suggestions/_index.md)

{{< /tab >}}

{{< tab title="コードレビューを改善" >}}

**Perfect for**（おすすめ）: レビュアーとチームリーダー

このパスに従って、次の方法を学習します:

- マージリクエストの説明を生成する
- AIネイティブコードレビューを入手する
- レビューコメントを要約してコミットメッセージを生成する

[開始場所: マージリクエストにおけるGitLab Duo →](../project/merge_requests/duo_in_merge_requests.md)

{{< /tab >}}

{{< tab title="アプリケーションを保護" >}}

**Perfect for**（おすすめ）: セキュリティおよびDevSecOpsの専門家

このパスに従って、次の方法を学習します:

- 脆弱性を理解する
- 自動的に修正候補を生成する
- セキュリティのイシューに対処するためのマージリクエストを作成する

[開始場所: 脆弱性の説明と解決策 →](../application_security/vulnerabilities/_index.md#vulnerability-explanation)

{{< /tab >}}

{{< /tabs >}}

## クイックスタート {#quick-start}

GitLab Duoをすぐに使用したいですか？方法は次のとおりです:

1. GitLab UIの右上隅、またはIDEで**GitLab Duo Chat**を選択して、GitLab Duo Chatを開きます。
1. プロジェクト、コード、またはGitLabの使用方法に関する質問をします。
1. IDEのコード提案などのAIネイティブ機能を試すか、チャットを使用します:

   - UIで、かさばるイシューを要約します。
   - IDEで、既存のコードをリファクタリングします。

[GitLab Duoの可能性をすべて表示 →](_index.md)

## 一般的なタスク {#common-tasks}

何か特定のことをする必要がありますか？一般的なタスクを次に示します:

| タスク | 説明 | クイックガイド |
|------|-------------|-------------|
| AI支援を受ける | コード、プロジェクト、またはGitLabに関する質問をGitLab Duoに質問する | [GitLab Duo Chat](../gitlab_duo_chat/_index.md) → |
| コードを生成 | IDEに入力すると、コード提案が表示される | [コード提案](../project/repository/code_suggestions/_index.md) → |
| コードを理解する | 平易な言語で説明されているコードがある | [コードの説明](../project/repository/code_explain.md) → |
| CI/CDのイシューを修正する | 失敗したジョブを分析して修正する | [根本原因分析](../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) → |
| 変更を要約する | マージリクエストの説明を生成する | [マージリクエストのサマリー](../project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes) → |

## GitLab Duoがワークフローとどのように統合されているか {#how-gitlab-duo-integrates-with-your-workflow}

GitLab Duoは、開発プロセスと統合されており、以下で使用できます:

- GitLab UI内
- GitLab Duo Chatを通じて
- IDE拡張機能内
- CLI内

## 経験レベル {#experience-levels}

### 初心者向け {#for-beginners}

GitLab Duoを初めて使用する場合は、次の機能から開始してください:

- **[GitLab Duo Chat](../gitlab_duo_chat/_index.md)** \- GitLabに関する質問や、基本的なタスクに関するヘルプを得られます。
- **[コード提案](../project/repository/code_suggestions/_index.md)** \- AIネイティブなコード補完をIDEで利用できます。
- **[コードの説明](../project/repository/code_explain.md)** \- ファイルやマージリクエストのコードを理解できます。
- **[Merge Request Summary](../project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes)**（Merge Request Summary） - 変更の説明を自動的に生成します。

### 中級ユーザー向け {#for-intermediate-users}

基本に慣れたら、これらのより高度な機能を試してください:

- **[テストの生成](../gitlab_duo_chat/examples.md#write-tests-in-the-ide)** \- コードのテストを自動的に作成します。
- **[Root Cause Analysis](../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)**（Root Cause Analysis） - 失敗したCI/CDジョブの問題を解決するを行います。

### 上級ユーザー向け {#for-advanced-users}

GitLab Duoで生産性を最大限に高める準備ができたら:

- **[GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md)** \- 独自のインフラストラクチャでLLMをホストします。
- **[GitLab Duo Agent Platform](../duo_agent_platform/_index.md)** \- 開発ワークフローのタスクを自動化します。
- **[Vulnerability Resolution](../application_security/vulnerabilities/_index.md#vulnerability-resolution)**（Vulnerability Resolution） - セキュリティイシューを修正するためのマージリクエストを自動的に生成します。

## ベストプラクティス {#best-practices}

GitLab Duoを効果的に使用するためのヒントを次に示します:

1. **Be specific in your prompts**（プロンプトで具体的にする）
   - より良い結果を得るために、明確なコンテキストを提供する
   - コードと目標に関する関連情報を記載する
   - コードタスクコマンド（`/explain`、`/refactor`、`/tests`など）をチャットで使用する

1. **Improve code responsibly**（責任を持ってコードを改善する）
   - AIが生成したコードは、使用する前に必ずレビューしてください
   - 生成されたコードをテストして、期待どおりに動作することを確認する
   - 適切なレビューで脆弱性の解決を使用する

1. **Refine iteratively**（反復的に改良する）
   - 応答が役に立たない場合は、質問を絞り込む
   - 複雑なリクエストをより小さなパーツに分割してみる
   - コンテキストを改善するために、詳細を追加する

1. **Leverage Chat for learning**（学習のためにチャットを活用する）
   - よくわからないGitLab機能について質問する
   - エラーメッセージと問題の説明を入手する
   - 特定のテクノロジーのベストプラクティスを学ぶ

## 次の手順 {#next-steps}

さらに詳しく知りたいですか？これらのリソースを試してください:

- [GitLab Duoのユースケース](use_cases.md) \- 実用的な例と演習
- [GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md) \- データを完全に制御する

## トラブルシューティング {#troubleshooting}

問題がありますか？これらの一般的な解決策を確認してください:

- [GitLab Duo機能がセルフマネージドで動作しない](troubleshooting.md#gitlab-duo-features-do-not-work-on-self-managed)
- [GitLab Duo機能がユーザーで使用できない](troubleshooting.md#gitlab-duo-features-not-available-for-users)
- [ヘルスチェックを実行](../../administration/gitlab_duo/setup.md#run-a-health-check-for-gitlab-duo)して、GitLab Duoの設定を診断します

さらにヘルプが必要ですか？GitLabドキュメントを検索するか、[GitLabコミュニティに質問](https://forum.gitlab.com/)してください。
