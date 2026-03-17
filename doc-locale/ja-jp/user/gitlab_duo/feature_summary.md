---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: AIネイティブの機能と機能性。
title: GitLab Duo (Classic) 機能
---

{{< history >}}

- [GitLab Duoが最初に導入された](https://about.gitlab.com/blog/gitlab-ai-assisted-features/)のはGitLab 16.0です。
- GitLab 16.6で[サードパーティAIの設定が削除されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136144)。
- GitLab 16.6で[GitLab Duoの全機能からOpenAIのサポートが削除されました](https://gitlab.com/groups/gitlab-org/-/epics/10964)。

{{< /history >}}

以下の機能は、GitLab.com、GitLab Self-Managed、GitLab Dedicatedで一般提供になりました。これらの機能を使用するには、PremiumまたはUltimateのサブスクリプションと、利用可能なアドオンのいずれかが必要です。

GitLab Duo with Amazon Qの機能は、別途アドオンとして提供されており、GitLab Self-Managedでのみ利用できます。

| 機能 | GitLab Duo Core | GitLab Duo Pro | GitLab Duo Enterprise | GitLab Duo with Amazon Q |
|---------|----------|---------|----------------|--------------------------|
| [コード提案（クラシック）](../project/repository/code_suggestions/_index.md) | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [GitLab Duo Chat（クラシック）](../gitlab_duo_chat/_index.md) | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| IDEでの[コードの説明](../gitlab_duo_chat/examples.md#explain-selected-code) | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| IDEでの[コードのリファクタリング](../gitlab_duo_chat/examples.md#refactor-code-in-the-ide) | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| IDEでの[コードの修正](../gitlab_duo_chat/examples.md#fix-code-in-the-ide) | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| IDEでの[テスト生成](../gitlab_duo_chat/examples.md#write-tests-in-the-ide) | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab UIでの[コードの説明](../project/repository/code_explain.md) | {{< no >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [ディスカッションサマリー](../discussions/_index.md#summarize-issue-discussions-with-gitlab-duo-chat) | {{< no >}} | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [コードレビュー<br>(Classic)](code_review_classic.md) <sup>1</sup> | {{< no >}} | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [根本原因分析](../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) | {{< no >}} | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [脆弱性の説明](../application_security/analyze/duo.md) | {{< no >}} | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [脆弱性の修正](../application_security/remediate/duo.md) | {{< no >}} | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [GitLab DuoとSDLCのトレンド](../analytics/duo_and_sdlc_trends.md) | {{< no >}} | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [マージコミットメッセージ生成](../project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message) | {{< no >}} | {{< no >}} | {{< yes >}} | {{< yes >}} |

**脚注**: 

1. Amazon Qは、この機能の異なるバージョンをサポートしています。[Amazon Qを使用してコードをレビューする方法を参照してください](../duo_amazon_q/_index.md#review-a-merge-request)。

## ベータ版および実験的機能 {#beta-and-experimental-features}

以下の機能はまだ一般公開されていません。

これらはPremiumまたはUltimateのサブスクリプションとGitLab Duo Enterpriseのアドオンが必要です。

| 機能 | GitLab Duo Core | GitLab Duo Pro | GitLab Duo Enterprise | GitLab Duo with Amazon Q |
|---------|-----------------|----------------|-----------------------|--------------------------|
| [マージリクエストサマリー](../project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes) | {{< no >}} | {{< no >}} | {{< yes >}} | {{< no >}} |
| [コードレビューサマリー](../project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review) | {{< no >}} | {{< no >}} | {{< yes >}} | {{< no >}} |
| [イシュー説明の生成](../project/issues/managing_issues.md#populate-an-issue-with-issue-description-generation) | {{< no >}} | {{< no >}} | {{< yes >}} | {{< no >}} |

## GitLab Duo Self-Hostedで利用可能な機能 {#features-available-in-gitlab-duo-self-hosted}

組織は独自の言語モデルをセルフホストできます。

GitLab Duo Self-Hostedで利用可能なGitLab Duo機能を確認するには、[サポートされている機能のリスト](../../administration/gitlab_duo_self_hosted/_index.md#feature-versions-and-status)を参照してください。

## GitLab Duo with Amazon Qに含まれるAmazon Q Developer Pro {#amazon-q-developer-pro-included-with-gitlab-duo-with-amazon-q}

[Amazon Q Developer Pro](https://aws.amazon.com/q/developer/)のライセンスクレジットは、GitLab Duo with Amazon Qのサブスクリプションに含まれています。

このサブスクリプションには、次のエージェント型チャットおよびコマンドラインツールへのアクセスが含まれます:

- [IDEでのAmazon Q Developer](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/q-in-IDE.html)。Visual Studio、VS Code、JetBrains、Eclipseを含む。
- [コマンドラインでのAmazon Q Developer](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line.html)。
- [AWS Management ConsoleでのAmazon Q Developer](https://aws.amazon.com/q/developer/operate/)。

Amazon Q Developerの機能の詳細については、[AWSのWebサイト](https://aws.amazon.com/q/developer/)を参照してください。
