---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: フロー
---

{{< details >}}

- プラン: [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier-on-gitlabcom)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

{{< history >}}

- GitLab 18.4で`ai_catalog_flows`[フラグ](../../../administration/feature_flags/_index.md)とともに[実験的機能](../../../policy/development_stages_support.md)として導入されました。デフォルトでは無効になっています。
- GitLab 18.7で[ベータ版](../../../policy/development_stages_support.md)に変更されました。
- GitLab 18.7の[GitLab.comで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/569060)。
- GitLab 18.8の[GitLab Self-ManagedおよびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/569060)になりました。
- 基本フローには、追加のフラグが必要です。
- GitLab 18.8で基本フローは[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。
- GitLab 18.8でカスタムフローはベータ版に[変更](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)されました。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

フローとは、1つ以上のエージェントを連携させて、複雑な問題を解決するための仕組みです。

GitLabでは、次の2種類のフローを利用できます:

- [基本フロー](foundational_flows/_index.md)は、GitLabが一般的な開発タスク向けに作成した、事前構築済みで本番環境に対応したワークフローです。
- [カスタムフロー](custom.md)は、チーム固有のプロセスを自動化するために作成するワークフローです。ワークフローのステップやエージェントを定義し、フローの実行を制御するトリガーを定義します。

フローは、IDEとGitLab UIで利用できます。

- UIでは、フローはGitLab CI/CDで直接実行され、ブラウザを離れることなく一般的な開発タスクを自動化できます。
- IDEでは、VS Code、Visual Studio、JetBrainsでソフトウェア開発フローを利用できます。その他のフローについてもサポートが提案されています。

CI/CDにおけるフローの実行方法について詳しくは、[フロー実行のドキュメント](execution.md)を参照してください。フローのセキュリティについて詳しくは、[複合アイデンティティのドキュメント](../composite_identity.md)を参照してください。

## 前提条件 {#prerequisites}

フローを使用するには:

- [前提条件](../_index.md#prerequisites)を満たしている必要があります。

GitLab UIでフローを実行するには:

- [GitLab Duoの設定](../../gitlab_duo/turn_on_off.md)でフローをオンにする必要があります。
- コードを作成するフローを使用するには、[サービスアカウントを許可するようにプッシュルールを設定](../troubleshooting.md#configure-push-rules-to-allow-a-service-account)する必要があります。
- [独自のRunnerを構成する](execution.md#configure-runners)か、または[GitLabホスト型Runner](../../../ci/runners/hosted_runners/_index.md)がプロジェクトで有効になっており、動作していることを確認します。

## GitLab UIで実行中のフローを監視する {#monitor-running-flows-in-the-gitlab-ui}

プロジェクトで実行中のフローを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **自動化** > **セッション**を選択します。

## IDEでフローの履歴を表示する {#view-flow-history-in-the-ides}

プロジェクトで実行したフローの履歴を表示するには:

- **フロー**タブで、下にスクロールして**最近のエージェントセッション**を確認します。

## `AGENTS.md`でフローをカスタマイズする {#customize-flows-with-agentsmd}

`AGENTS.md`ファイルを使用して、基本フローとカスタムフローの実行時に、GitLab Duoが従うコンテキストと指示を提供できます。

詳細については、[`AGENTS.md`カスタマイズファイル](../../gitlab_duo/customize_duo/agents_md.md)を参照してください。

## フィードバックを提供する {#give-feedback}

フローは、GitLabのAI搭載開発プラットフォームの一部です。皆様からのフィードバックは、これらのワークフローの改善に役立ちます。フローに関する問題の報告または改善提案を行うには、[こちらのアンケートにご記入ください](https://gitlab.fra1.qualtrics.com/jfe/form/SV_9GmCPTV7oH9KNuu)。

## 関連トピック {#related-topics}

- [フローの実行場所を設定する](execution.md)
- [基本フロー](foundational_flows/_index.md)
