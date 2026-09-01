---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 複数のエージェントを使用して、基本フローとカスタムフローにより複雑な開発タスクを自動化します。
title: フロー
---

{{< details >}}

- プラン: [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

{{< history >}}

- GitLab 18.4で`ai_catalog_flows`[機能フラグ](../../../administration/feature_flags/_index.md)とともに[実験的機能](../../../policy/development_stages_support.md)として導入されました。デフォルトでは無効になっています。
- GitLab 18.7で[ベータ版](../../../policy/development_stages_support.md)に変更されました。
- GitLab 18.7の[GitLab.comで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/569060)。
- GitLab 18.8の[GitLab Self-ManagedおよびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/569060)になりました。
- 機能フラグ`ai_catalog_flows`は、GitLab 18.8で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216969)になっています。
- 基本フローには、追加のフラグが必要です。
- 基本フローはGitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)に変わりました。
- カスタムフローはGitLab 18.8で[ベータ](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)に変わりました。
- GitLab 19.2で機能フラグ`ai_catalog_flows`は[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239459)されました。
- カスタムフローはGitLab 19.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/602415)に変わりました。

{{< /history >}}

フローとは、1つ以上のエージェントを連携させて、複雑な問題を解決するための仕組みです。

GitLabでは、次の2種類のフローを利用できます:

- [基本フロー](foundational_flows/_index.md)は、GitLabが一般的な開発タスク向けに作成した、事前構築済みで本番環境に対応したワークフローです。
- [カスタムフロー](custom.md)は、チーム固有のプロセスを自動化するために作成するワークフローです。ワークフローのステップやエージェントを定義し、フローの実行を制御するトリガーを定義します。

フローは、IDEとGitLab UIで利用できます。

- UIでは、フローはGitLab CI/CDで直接実行され、ブラウザを離れることなく一般的な開発タスクを自動化できます。
- IDEでは、VS Code、Visual Studio、JetBrainsでソフトウェア開発フローを利用できます。その他のフローについてもサポートが提案されています。

CI/CDにおけるフローの実行方法について詳しくは、[フロー実行のドキュメント](execution.md)を参照してください。フローのセキュリティについて詳しくは、[複合アイデンティティのドキュメント](../composite_identity.md)を参照してください。

## 前提条件 {#prerequisites}

<!-- Note: These prerequisites are duplicated on each flow sub-page. Update all pages when editing. -->

- [GitLab Duo Agent Platformの前提条件](../_index.md#prerequisites)を満たしていること。
- **基本フローを許可**を[トップレベルグループ向けに](foundational_flows/_index.md#turn-foundational-flows-on-or-off)有効にします。
- [サービスアカウントを許可するようにプッシュルールを設定していること](../troubleshooting.md#configure-push-rules-to-allow-a-service-account)。
- プロジェクトで[独自のRunnerを設定](execution/_index.md#configure-runners-to-execute-flows)しているか、[GitLabホストRunner](../../../ci/runners/hosted_runners/_index.md)を有効にしていること。

## GitLab UIで実行中のフローを監視する {#monitor-running-flows-in-the-gitlab-ui}

プロジェクトで実行中のフローを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**AI** > **セッション**を選択します。

## IDEでフローの履歴を表示する {#view-flow-history-in-the-ides}

プロジェクトで実行したフローの履歴を表示するには:

- **フロー**タブで、下にスクロールして**最近のエージェントセッション**を確認します。

## `AGENTS.md`でフローをカスタマイズする {#customize-flows-with-agentsmd}

`AGENTS.md`ファイルを使用して、基本フローとカスタムフローの実行時に、GitLab Duoが従うコンテキストと指示を提供できます。

詳細については、[`AGENTS.md`カスタマイズファイル](../customize/agents_md.md)を参照してください。

## フィードバックを提供する {#give-feedback}

フローは、GitLabのAI搭載開発プラットフォームの一部です。皆様からのフィードバックは、これらのワークフローの改善に役立ちます。フローに関する問題の報告または改善提案を行うには、[こちらのアンケートにご記入ください](https://gitlab.fra1.qualtrics.com/jfe/form/SV_9GmCPTV7oH9KNuu)。

## 関連トピック {#related-topics}

- [フローの実行場所を設定する](execution.md)
- [基本フロー](foundational_flows/_index.md)
