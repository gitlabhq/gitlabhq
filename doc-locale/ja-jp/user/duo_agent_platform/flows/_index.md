---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: フロー
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

この機能は[GitLabクレジット](../../../subscriptions/gitlab_credits.md)を使用します。

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

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

フローとは、1つまたは複数のエージェントが連携して複雑な問題を解決する組み合わせのことです。

GitLabには、次の2種類のフローがあります:

- [基本フロー](foundational_flows/_index.md)は、GitLabが一般的なソフトウェア開発タスクのために作成した、事前構築済みの本番環境対応ワークフローです。
- [Custom flows](custom.md)は、チーム固有のプロセスを自動化するために作成するワークフローです。ワークフローのステップとエージェントを定義し、フローの実行を制御するトリガーを定義します。

フローは、IDEとGitLab UIで利用できます。

- UIでは、GitLab CI/CDで直接実行され、ブラウザを離れることなく、一般的なソフトウェア開発タスクを自動化できます。
- IDEでは、ソフトウェア開発フローは、VS Code、Visual Studio、JetBrainsで利用できます。他のフローのサポートも提案されています。

CI/CDでのフローの実行方法について詳しくは、[flow executionドキュメント](execution.md)をご覧ください。フローのセキュリティについて詳しくは、[the composite identityドキュメント](../security.md)をご覧ください。

## 前提条件 {#prerequisites}

フローを使用するには:

- [前提条件](../_index.md#prerequisites)を満たす必要があります。

GitLab UIでフローを実行するには:

- [GitLab Duoの設定](../../gitlab_duo/turn_on_off.md)でフローをオンにする必要があります。
- フローを初めて追加または実行する前に、[プロジェクトが所属するグループにメンバーを追加できるようにする必要があります](../troubleshooting.md#allow-members-to-be-added-to-projects)。
- コードを作成するフローを使用するには、[サービスアカウントを許可するようにプッシュルールを構成](../troubleshooting.md#configure-push-rules-to-allow-a-service-account)する必要があります。

## GitLab UIで実行中のフローを監視 {#monitor-running-flows-in-the-gitlab-ui}

プロジェクトで実行されているフローを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **自動化** > **セッション**を選択します。

## IDEでフローの履歴を表示 {#view-flow-history-in-the-ides}

プロジェクトで実行したフローの履歴を表示するには:

- **フロー**タブで、下にスクロールして**Recent agent sessions**を表示します。

## `AGENTS.md`でフローをカスタマイズ {#customize-flows-with-agentsmd}

`AGENTS.md`ファイルを使用して、基本フローとカスタムフローを実行中に従うコンテキストと手順をGitLab Duoに提供します。

詳細については、[`AGENTS.md`のカスタマイズファイル](../../gitlab_duo/customize_duo/agents_md.md)を参照してください。

## フィードバックを提供する {#give-feedback}

フローは、GitLab AI搭載のソフトウェア開発プラットフォームの一部です。皆様からのフィードバックは、これらのワークフローの改善に役立ちます。フローに関するイシューのレポートや改善案を提案するには、[このアンケートにご回答ください](https://gitlab.fra1.qualtrics.com/jfe/form/SV_9GmCPTV7oH9KNuu)。

## 関連トピック {#related-topics}

- [Configure where flows run](execution.md)
- [基本フロー](foundational_flows/_index.md)
