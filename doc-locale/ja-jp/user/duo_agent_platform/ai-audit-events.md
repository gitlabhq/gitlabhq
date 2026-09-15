---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: コンプライアンスおよびガバナンスの目的で、GitLab Duoエージェントのアクティビティを一元的に記録したデータを閲覧およびフィルタリングします。
title: AI監査イベント
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
> この機能は[ベータ版](../../policy/development_stages_support.md)です。予告なく変更される場合があります。詳細については、[GitLabテスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)を参照してください。

統一された閲覧可能な記録として、GitLab DuoエージェントアクティビティのAI監査イベントレポートを使用します。エージェントセッションごとに、確認可能な包括的な監査アーティファクトが生成されます。

## AI監査イベントを表示する {#view-ai-audit-events}

AI監査イベントは、**ガバナンス**ページの**監査イベント**タブで利用できます。

前提条件: 

- トップレベルグループのオーナーロールが必要です。

グループのAI監査イベントを表示するには:

1. 上部のバーで**検索または移動先**を選択して、トップレベルグループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **ガバナンスを変更**を選択します。
1. **エージェントアーティファクト**タブを選択します。

このタブには、エージェントセッションのリストが表示されます。各行には次の情報が表示されます:

- エージェントの種類（ワークフロー定義）。
- セッションが実行されたプロジェクト。
- セッション内の監査イベント数。
- セッションの開始時刻。

## セッションをフィルタリングする {#filter-sessions}

セッションリストをフィルタリングして、結果を絞り込むことができます:

- **プロジェクト**: プロジェクトパスでフィルタリングするか、特定のプロジェクトを除外します。
- **日付範囲**: 特定の日付より後または前に作成されたセッションをフィルタリングします。

## セッションの詳細を表示する {#view-session-details}

セッション内のイベントを確認するには:

1. セッションの行を選択して、セッションの詳細パネルを開きます。このパネルには、セッションのメタデータと監査イベントの時系列リストが表示されます。
1. 個々のイベントを選択して、エンティティやターゲット情報を含む詳細全体を表示します。

## AI監査イベントの保存を有効にする {#enable-ai-audit-event-storage}

{{< history >}}

- GitLab 19.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/603892)されました。

{{< /history >}}

AI監査イベントの保存はデフォルトでは無効になっています。エージェントセッションのデータがデータベースまたはClickHouseに書き込まれるようにするには、保存を明示的に有効にする必要があります。保存を無効にしても、AI監査イベントのリアルタイムストリーミングには影響しません。

この設定は、インスタンスからグループ、プロジェクトへとカスケードされます:

- グループレベルで無効にしてロックすると、そのグループ内のプロジェクトでは設定をオーバーライドできません。
- グループレベルで有効にしてロックすると、そのグループ内のすべてのプロジェクトで保存が有効になり、無効にすることはできません。

前提条件: 

- グループまたはプロジェクトのオーナーロールまたはセキュリティマネージャーロールが必要です。

### グループで保存を有効にする {#enable-storage-for-a-group}

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **データとプライバシー**セクションで、**AI監査イベントを保存**を選択します。
1. **変更を保存**を選択します。

### プロジェクトで保存を有効にする {#enable-storage-for-a-project}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duo**セクションを展開します。
1. **AI監査イベントを保存**切替をオンにします。
1. **変更を保存**を選択します。

設定が親グループによってロックされている場合、コントロールは無効になり、プロジェクトレベルで変更することはできません。

## 複合IDによるイベントの属性付与 {#event-attribution-with-composite-identity}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/247149)されました。

{{< /history >}}

エージェントセッションが[composite identity](composite_identity.md)（エージェントセッションのデフォルトID）で実行されると、そのセッションのAI監査イベントはサービスアカウントに帰属します。`author_id`フィールドにはサービスアカウントのユーザーIDが含まれ、サービスアカウントがイベント作成者として表示されます。

イベントの`details`フィールドには、セッションを開始した人間のユーザーが記録されます:

| フィールド                   | 説明                |
|-------------------------|----------------------------|
| `human_author_id`       | 人間のユーザーのユーザーID  |
| `human_author_name`     | 人間のユーザーの名前     |
| `human_author_username` | 人間のユーザーのユーザー名 |

セッションが人間のユーザー自身のトークンで認証された場合、人間のユーザーがイベント作成者となり、`human_author_*`フィールドは追加されません。

## 関連トピック {#related-topics}

- [GitLab Duo Agent Platform](_index.md)
- [監査イベント](../compliance/audit_events.md)
- [監査イベントタイプ](../compliance/audit_event_types.md)
- [監査イベントレポート](../../administration/compliance/audit_event_reports.md)
