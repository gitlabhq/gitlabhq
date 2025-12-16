---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: AIネイティブの機能と機能性。
title: GitLab Duoの機能の概要
---

{{< history >}}

- GitLab 16.0で[GitLab Duoの最初の機能が導入されました](https://about.gitlab.com/blog/2023/05/03/gitlab-ai-assisted-features/)。
- GitLab 16.6で[サードパーティAIの設定が削除されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136144)。
- GitLab 16.6で[GitLab Duoの全機能からOpenAIのサポートが削除されました](https://gitlab.com/groups/gitlab-org/-/epics/10964)。

{{< /history >}}

以下の機能は、GitLab.com、GitLab Self-Managed、GitLab Dedicatedで一般提供になりました。これらの機能を使用するには、PremiumまたはUltimateのサブスクリプションと、利用可能なアドオンのいずれかが必要です。

GitLab Duo with Amazon Qの機能は、別途アドオンとして提供されており、GitLab Self-Managedでのみ利用できます。

| 機能 | GitLab Duo Core | GitLab Duo Pro | GitLab Duo Enterprise | GitLab Duo with Amazon Q |
|---------|----------|---------|----------------|--------------------------|
| [コード提案](../project/repository/code_suggestions/_index.md) | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| [GitLab Duo Chat（クラシック）](../gitlab_duo_chat/_index.md) | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| IDEでの[コードの説明](../gitlab_duo_chat/examples.md#explain-selected-code) | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| IDEでの[コードのリファクタリング](../gitlab_duo_chat/examples.md#refactor-code-in-the-ide) | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| IDEでの[コードの修正](../gitlab_duo_chat/examples.md#fix-code-in-the-ide) | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| IDEでの[テスト生成](../gitlab_duo_chat/examples.md#write-tests-in-the-ide) | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| GitLab UIでの[コードの説明](../project/repository/code_explain.md) | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| [ディスカッションサマリー](../discussions/_index.md#summarize-issue-discussions-with-duo-chat) | {{< icon name="dash-circle" >}}非対応 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| [コードレビュー](../project/merge_requests/duo_in_merge_requests.md#have-gitlab-duo-review-your-code) | {{< icon name="dash-circle" >}}非対応 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応<sup>1</sup> |
| [根本原因分析](../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) | {{< icon name="dash-circle" >}}非対応 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| [脆弱性の説明](../application_security/vulnerabilities/_index.md#vulnerability-explanation)<sup>3</sup> | {{< icon name="dash-circle" >}}非対応 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| [脆弱性の解決](../application_security/vulnerabilities/_index.md#vulnerability-resolution)<sup>3</sup> | {{< icon name="dash-circle" >}}非対応 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| [GitLab DuoとSDLCの傾向](../analytics/duo_and_sdlc_trends.md)<sup>3</sup> | {{< icon name="dash-circle" >}}非対応 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled">}}対応 |
| [マージコミットメッセージ生成](../project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message) | {{< icon name="dash-circle" >}}非対応 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| [CLI用GitLab Duo](../../editor_extensions/gitlab_cli/_index.md#gitlab-duo-for-the-cli) | {{< icon name="dash-circle" >}}非対応 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応<sup>2</sup> |

**脚注**: 

1. Amazon Qは、この機能の異なるバージョンをサポートしています。[Amazon Qを使用してコードをレビューする方法を参照してください](../duo_amazon_q/_index.md#review-a-merge-request)。
1. Amazon Qは、この機能の異なるバージョンをサポートしています。[詳細](#amazon-q-developer-pro-included-with-gitlab-duo-with-amazon-q)を参照してください。
1. Ultimateプランのサブスクリプションが必要です。

## ベータ版および実験的機能 {#beta-and-experimental-features}

{{< history >}}

- GitLab Duo Agentic Chatは、GitLab 18.2で追加されました。

{{< /history >}}

以下の機能は一般提供されていません。

これらの機能を使用するには、PremiumまたはUltimateのサブスクリプションと、利用可能なアドオンのいずれかが必要です。

| 機能 | GitLab Duo Core | GitLab Duo Pro | GitLab Duo Enterprise | GitLab Duo with Amazon Q | GitLab.com | GitLab Self-Managed | GitLab Dedicated | GitLab Duo Self-Hosted |
|---------|----------|---------|----------------|--------------------------|-----------|-------------|-----------|------------------------|
| [コードレビューサマリー](../project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review) | {{< icon name="dash-circle" >}}非対応 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}非対応 | 実験的機能 | 実験的機能 | 実験的機能 | 実験的機能 |
| [イシュー説明の生成](../project/issues/managing_issues.md#populate-an-issue-with-issue-description-generation) | {{< icon name="dash-circle" >}}非対応 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}非対応 | 実験的機能 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="dash-circle" >}}非対応 | 該当なし |
| [マージリクエストサマリー](../project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes) | {{< icon name="dash-circle" >}}非対応 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}非対応 | ベータ版 | ベータ版 | {{< icon name="dash-circle" >}}非対応 | ベータ版 |
| [GitLab Duo Chat（エージェント）](../gitlab_duo_chat/agentic_chat.md) | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応<sup>1</sup> | ベータ版 | ベータ版 | ベータ版 | {{< icon name="dash-circle" >}}非対応 |
| [CLIエージェント](../duo_agent_platform/agent_assistant.md) | {{< icon name="dash-circle" >}}非対応 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | 実験的機能 | 実験的機能 | 実験的機能 | {{< icon name="check-circle-filled" >}}対応 |
| [GitLab Duo Agent Platform](../duo_agent_platform/_index.md) | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}非対応 | ベータ版 | ベータ版 | ベータ版 | {{< icon name="dash-circle" >}}非対応 |

**脚注**: 

1. Amazon Qは、この機能の異なるバージョンをサポートしています。[詳細](#amazon-q-developer-pro-included-with-gitlab-duo-with-amazon-q)を参照してください。

## GitLab Duo Self-Hostedで利用可能な機能 {#features-available-in-gitlab-duo-self-hosted}

以下の条件を満たす場合、[GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md)を使用してAIゲートウェイと言語モデルをセルフホストできます:

- GitLab Duo Enterpriseアドオンをお持ちの場合。
- GitLab Self-Managedをご利用の場合。

GitLab Duo Self-Hostedで使用できるGitLab Duo機能とそのステータスを確認するには、[GitLab Duo Self-Hosted対応のGitLab Duo機能](../../administration/gitlab_duo_self_hosted/_index.md#supported-gitlab-duo-features)を参照してください。

## GitLab Duo with Amazon Qに含まれるAmazon Q Developer Pro {#amazon-q-developer-pro-included-with-gitlab-duo-with-amazon-q}

[Amazon Q Developer Pro](https://aws.amazon.com/q/developer/)のライセンスクレジットは、GitLab Duo with Amazon Qのサブスクリプションに含まれています。

このサブスクリプションには、次のエージェント型チャットおよびコマンドラインツールへのアクセスが含まれます:

- [IDEでのAmazon Q Developer](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/q-in-IDE.html)。Visual Studio、VS Code、JetBrains、Eclipseを含む。
- [コマンドラインでのAmazon Q Developer](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line.html)。
- [AWS Management ConsoleでのAmazon Q Developer](https://aws.amazon.com/q/developer/operate/)。

Amazon Q Developerの機能の詳細については、[AWSのWebサイト](https://aws.amazon.com/q/developer/)を参照してください。
