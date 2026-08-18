---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: コンプライアンスおよびガバナンス目的で、GitLab Duoエージェントアクティビティの統一された記録を参照およびフィルタリングします。
title: AI監査イベントレポート
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.1で`agent_artifacts_page`[機能フラグ](../../administration/feature_flags/_index.md)とともに[ベータ版](../../policy/development_stages_support.md)として[導入](https://gitlab.com/groups/gitlab-org/-/work_items/20237)されました。デフォルトでは無効になっています。
- GitLab 19.2でデフォルトで有効になりました。

{{< /history >}}

> [!warning]
> この機能は[ベータ](../../policy/development_stages_support.md)版です。予告なく変更される場合があります。詳細については、[GitLabテスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)を参照してください。

このAI監査イベントレポートは、セキュリティチームおよびコンプライアンスチームに、GitLab Duoエージェント活動の統合された閲覧可能な記録を提供します。各エージェントセッションは、検査可能な包括的な監査アーティファクトを生成します。

## AI監査イベントを表示 {#view-ai-audit-events}

AI監査イベントは、**ガバナンス**ページの**監査イベント**タブで利用できます。

前提条件: 

- トップレベルグループのオーナーロールが必要です。

グループのAI監査イベントを表示するには:

1. 上部のバーで**検索または移動先**を選択して、トップレベルグループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **ガバナンスを変更**を選択します。
1. **エージェントアーティファクト**タブを選択します。

タブにはエージェントセッションのリストが表示されます。各行に表示されるのは次のとおりです:

- エージェントの種類（ワークフロー定義）。
- セッションが実行されたプロジェクト。
- セッション内の監査イベントの数。
- セッションの開始時刻。

## セッションをフィルター {#filter-sessions}

結果を絞り込むために、セッションリストをフィルターできます:

- **プロジェクト**: プロジェクトパスでフィルターするか、特定のプロジェクトを除外する。
- **日付範囲**: 特定の日付以降または以前に作成されたセッションをフィルターする。

## セッションの詳細を表示 {#view-session-details}

セッション内のイベントを検査するには:

1. セッション行を選択して、セッション詳細パネルを開きます。パネルには、セッションメタデータと監査イベントの時系列リストが表示されます。
1. 個々のイベントを選択して、エンティティとターゲット情報を含む完全な詳細を表示します。

## AI監査イベントストレージを有効にする {#enable-ai-audit-event-storage}

{{< history >}}

- GitLab 19.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/work_items/603892)。

{{< /history >}}

AI監査イベントストレージはデフォルトで無効になっています。エージェントセッションデータがデータベースまたはClickHouseに書き込まれる前に、ストレージを明示的に有効にする必要があります。ストレージを無効にしても、AI監査イベントのリアルタイムストリーミングには影響しません。

この設定はインスタンスからグループ、プロジェクトへとカスケードされます:

- グループレベルで無効かつロックされている場合、そのグループ内のプロジェクトは設定を上書きできません。
- グループレベルで有効かつロックされている場合、そのグループ内のすべてのプロジェクトでストレージが有効になり、無効にすることはできません。

前提条件: 

- グループまたはプロジェクトのオーナーロールまたはセキュリティマネージャーロールが必要です。

### グループのストレージを有効にする {#enable-storage-for-a-group}

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **Data privacy**セクションで、**Enable AI audit event storage**を選択します。
1. **変更を保存**を選択します。

### プロジェクトのストレージを有効にする {#enable-storage-for-a-project}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **Data privacy**セクションで、**Enable AI audit event storage**を選択します。
1. **変更を保存**を選択します。

親グループによって設定がロックされている場合、チェックボックスは無効になり、プロジェクトレベルでは変更できません。

## 関連トピック {#related-topics}

- [GitLab Duo Agent Platform](_index.md)
- [監査イベント](../../user/compliance/audit_events.md)
- [監査イベントタイプ](../../user/compliance/audit_event_types.md)
- [監査イベントレポート](../../administration/compliance/audit_event_reports.md)
