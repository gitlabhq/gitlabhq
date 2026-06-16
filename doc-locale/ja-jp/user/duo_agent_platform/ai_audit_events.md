---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duoエージェントアクティビティの統合された記録を参照、フィルタリング、ダウンロードして、コンプライアンスおよびガバナンスの目的で使用します。
title: AI監査イベントレポート
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.1で`agent_artifacts_page`[機能フラグ](../../administration/feature_flags/_index.md)とともに[ベータ版](../../policy/development_stages_support.md)として[導入](https://gitlab.com/groups/gitlab-org/-/work_items/20237)されたました。デフォルトでは無効になっています。

{{< /history >}}

> [!warning]
> この機能は[ベータ](../../policy/development_stages_support.md)版です。本機能は予告なしに変更されることがあります。詳細については、[GitLabテスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)を参照してください。

AI監査イベントレポートは、セキュリティチームとコンプライアンスチームに、GitLab Duoエージェントアクティビティの統合された閲覧可能な記録を提供します。各エージェントセッションは、検査およびダウンロード可能な包括的な監査アーティファクトを生成します。

## AI監査イベントを表示 {#view-ai-audit-events}

AI監査イベントは、**ガバナンス**ページの**エージェントアーティファクト**タブで利用できます。

前提条件: 

- トップレベルグループのオーナーロールが必要です。

グループのAI監査イベントを表示するには:

1. 上部のバーで**検索または移動先**を選択して、トップレベルグループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **ガバナンスの変更**を選択します。
1. **エージェントアーティファクト**タブを選択します。

このタブには、エージェントセッションのリストが表示されます。各行には以下が表示されます:

- エージェントタイプ（ワークフロー定義）。
- セッションが実行されたプロジェクト。
- セッション内の監査イベントの数。
- セッション開始時刻。

## セッションをフィルタリング {#filter-sessions}

セッションリストをフィルタリングして結果を絞り込むことができます:

- **エージェント**: ワークフロー定義名でフィルタリングするか、特定のエージェントを除外する。
- **プロジェクト**: プロジェクトパスでフィルタリングするか、特定のプロジェクトを除外する。
- **日付範囲**: 特定の日付以降または以前に作成されたセッションをフィルタリングします。

## セッションの詳細を表示 {#view-session-details}

セッション内のイベントを検査するには:

1. セッション行を選択して、セッション詳細パネルを開きます。このパネルには、セッションメタデータと監査イベントの時系列リストが表示されます。
1. 個々のイベントを選択して、エンティティとターゲット情報を含む完全な詳細を表示します。

## セッションアーティファクトをダウンロード {#download-a-session-artifact}

各セッションには、そのセッションの完全な監査記録を含むダウンロード可能なJSONアーティファクトがあります。

セッションアーティファクトをダウンロードするには、ダウンロードしたいセッションのセッション詳細パネルを開きます。

このアーティファクトはJSONドキュメントです。オフライン分析、長期保持、または外部コンプライアンスツールとのインテグレーションに使用できます。

## 関連トピック {#related-topics}

- [GitLab Duo Agent Platform](_index.md)
- [監査イベント](../../administration/compliance/audit_event_reports.md)
