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

以下の機能は、一般的にGitLab.com、GitLab Self-Managed、GitLab Dedicatedで利用できます。これらの機能を使用するには、PremiumまたはUltimateのサブスクリプションと、利用可能なアドオンのいずれかが必要です。

GitLab Duo with Amazon Qの機能は、別途アドオンとして利用でき、GitLab Self-Managedでのみ利用できます。

| 機能 | GitLab Duo Core | GitLab Duo Pro | GitLab Duo Enterprise | GitLab Duo with Amazon Q |
|---------|----------|---------|----------------|--------------------------|
| [コード提案](../project/repository/code_suggestions/_index.md) | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| [GitLab Duo Chat（クラシック）](../gitlab_duo_chat/_index.md) | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| IDEの[コードの説明](../gitlab_duo_chat/examples.md#explain-selected-code) | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| IDEの[コードをリファクタリングする](../gitlab_duo_chat/examples.md#refactor-code-in-the-ide) | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| IDEの[コードの修正](../gitlab_duo_chat/examples.md#fix-code-in-the-ide) | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| IDEの[テスト生成](../gitlab_duo_chat/examples.md#write-tests-in-the-ide) | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| GitLab UIの[コードの説明](../project/repository/code_explain.md) | {{< icon name="dash-circle" >}}不可 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| [ディスカッションサマリー](../discussions/_index.md#summarize-issue-discussions-with-duo-chat) | {{< icon name="dash-circle" >}}不可 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| [コードレビュー](../project/merge_requests/duo_in_merge_requests.md#have-gitlab-duo-review-your-code) | {{< icon name="dash-circle" >}}不可 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}はい<sup>1</sup> |
| [根本原因分析](../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) | {{< icon name="dash-circle" >}}不可 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| [脆弱性](../application_security/vulnerabilities/_index.md#vulnerability-explanation)の説明<sup>3</sup> | {{< icon name="dash-circle" >}}不可 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| [脆弱性](../application_security/vulnerabilities/_index.md#vulnerability-resolution)の解決<sup>3</sup> | {{< icon name="dash-circle" >}}不可 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| [GitLab DuoとSDLCの傾向](../analytics/duo_and_sdlc_trends.md) <sup>3</sup> | {{< icon name="dash-circle" >}}不可 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}はい |
| [マージコミットメッセージ生成](../project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message) | {{< icon name="dash-circle" >}}不可 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| [CLI用GitLab Duo](../../editor_extensions/gitlab_cli/_index.md#gitlab-duo-for-the-cli) | {{< icon name="dash-circle" >}}不可 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}はい<sup>2</sup> |

**脚注**: 

1. Amazon Qは、この機能の異なるバージョンをサポートしています。[Amazon Qを使用してコードをレビューする方法を表示する](../duo_amazon_q/_index.md#review-a-merge-request)。
1. Amazon Qは、この機能の異なるバージョンをサポートしています。[詳細](#amazon-q-developer-pro-included-with-gitlab-duo-with-amazon-q)を参照してください。
1. Ultimateプランのサブスクリプションが必要です。

## ベータ版および実験的機能を有効にする {#beta-and-experimental-features}

{{< history >}}

- GitLab Duo Agentic ChatがGitLab 18.2で追加されました。

{{< /history >}}

以下の機能は一般的に利用できません。

これらの機能を使用するには、PremiumまたはUltimateのサブスクリプションと、利用可能なアドオンのいずれかが必要です。

| 機能 | GitLab Duo Core | GitLab Duo Pro | GitLab Duo Enterprise | GitLab Duo with Amazon Q | GitLab.com | GitLab Self-Managed | GitLab Dedicated | GitLab Duo Self-Hosted |
|---------|----------|---------|----------------|--------------------------|-----------|-------------|-----------|------------------------|
| [コードレビューサマリー](../project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review) | {{< icon name="dash-circle" >}}不可 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}はい | {{< icon name="dash-circle" >}}不可 | 実験的機能 | 実験的機能 | 実験的機能 | 実験的機能 |
| [イシュー説明の生成](../project/issues/managing_issues.md#populate-an-issue-with-issue-description-generation) | {{< icon name="dash-circle" >}}不可 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}はい | {{< icon name="dash-circle" >}}不可 | 実験的機能 | {{< icon name="dash-circle" >}}不可 | {{< icon name="dash-circle" >}}不可 | 該当なし |
| [マージリクエストサマリー](../project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes) | {{< icon name="dash-circle" >}}不可 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}はい | {{< icon name="dash-circle" >}}不可 | ベータ | ベータ | {{< icon name="dash-circle" >}}不可 | ベータ |
| [GitLab Duo Agentic Chat](../gitlab_duo_chat/agentic_chat.md) | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}はい<sup>1</sup> | ベータ | ベータ | ベータ | {{< icon name="dash-circle" >}}不可 |
| [CLIエージェント](../duo_agent_platform/agent_assistant.md) | {{< icon name="dash-circle" >}}不可 | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | 実験的機能 | 実験的機能 | 実験的機能 | {{< icon name="check-circle-filled" >}}対応 |
| [GitLab Duo Agent Platform](../duo_agent_platform/_index.md)セッション | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}適用 | {{< icon name="dash-circle" >}}不可 | ベータ | ベータ | ベータ | {{< icon name="dash-circle" >}}不可 |

**脚注**: 

1. Amazon Qは、この機能の異なるバージョンをサポートしています。[詳細](#amazon-q-developer-pro-included-with-gitlab-duo-with-amazon-q)を参照してください。

## GitLab Duo Self-Hostedで利用可能な機能 {#features-available-in-gitlab-duo-self-hosted}

組織で[GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md)を使用すると、AIゲートウェイと言語モデルを自分でホストできます。:

- GitLab Duo Enterpriseアドオン
- GitLab Self-Managedのお客様であること。

GitLab Duo Self-Hostedで使用できるGitLab Duo機能とそのステータスを確認するには、[GitLab Duo Self-HostedでサポートされているGitLab Duo機能](../../administration/gitlab_duo_self_hosted/_index.md#supported-gitlab-duo-features)を参照してください。

## Amazon Q Developer ProはGitLab Duo with Amazon Qに含まれています {#amazon-q-developer-pro-included-with-gitlab-duo-with-amazon-q}

[Amazon Q Developer Pro](https://aws.amazon.com/q/developer/)のライセンスクレジットは、GitLab Duo with Amazon Qのサブスクリプションに含まれています。

このサブスクリプションには、次のエージェント型チャットおよびコマンドラインツールへのアクセスが含まれています。:

- [IDEのAmazon Q Developer](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/q-in-IDE.html)（Visual Studio、VS Code、JetBrains、Eclipseなど）。
- [コマンドラインのAmazon Q Developer](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line.html)。
- [AWS Management ConsoleのAmazon Q Developer](https://aws.amazon.com/q/developer/operate/)。

Amazon Q Developerの機能の詳細については、[AWSのWebサイト](https://aws.amazon.com/q/developer/)を参照してください。
