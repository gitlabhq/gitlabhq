---
stage: Agent Foundations
group: AI Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: プロジェクトでフローが実行されるタイミングを制御するトリガーを作成および管理します。
title: トリガー
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.3で、[機能フラグ](../../../administration/feature_flags/_index.md) `ai_flow_triggers`とともに導入されました。デフォルトでは有効になっています。
- GitLab 18.8で追加の`ai_catalog_create_third_party_flows`[フラグ](../../../administration/feature_flags/_index.md)が必要になるように[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217634)されました。デフォルトでは無効になっています。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。

{{< /history >}}

> [!flag]
> フロー設定ファイルの場所を変更するには、機能フラグを有効にする必要があります。詳細については、履歴を参照してください。

トリガーは、フローまたは外部エージェントをいつ実行するかを決定します。カスタムエージェントまたは基本エージェントに対してトリガーを作成することはできません。

たとえば、ディスカッションでフローのサービスアカウントユーザーにメンションしたとき、またはそのサービスアカウントユーザーをレビュアーとして割り当てたときに、フローがトリガーされるよう指定できます。

## トリガーを作成する {#create-a-trigger}

{{< history >}}

- GitLab 18.5で**割り当て**イベントタイプと**レビュアーを割り当てる**イベントタイプが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/567787)されました。
- GitLab 18.9でパイプラインイベントトリガーイベントタイプが`ai_flow_trigger_pipeline_hooks`[フラグ](../../../administration/feature_flags/_index.md)とともに[実験的機能](../../../policy/development_stages_support.md)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212797)されました。デフォルトでは無効になっています。
- GitLab 19.0で**マージリクエスト準備完了**トリガーイベントタイプが`merge_request_ready_flow_trigger`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/592454)されました。デフォルトでは無効になっています。
- GitLab 19.1で**マージリクエストコードコンフリクト**トリガーイベントタイプが[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234044)されました。
- GitLab 19.1で**マージリクエスト**トリガーイベントタイプと**承認済み**アクションが[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237081)されました。
- 機能フラグ`ai_flow_trigger_pipeline_hooks`はGitLab 19.1で[削除](https://gitlab.com/gitlab-org/gitlab/-/work_items/587272)されました。
- GitLab 19.1で**作業アイテムの作成**トリガーイベントタイプが[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/599985)されました。
- GitLab 19.1で**マージリクエスト準備完了**トリガーイベントタイプは[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/598421)になりました。機能フラグ`merge_request_ready_flow_trigger`は削除されました。
- GitLab 19.2で**作業アイテムのステータス変更**トリガーイベントタイプが[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/599983)されました。
- GitLab 19.2で、**Merge request ready**および**Merge request code conflict**イベントタイプは、**マージリクエスト**イベントタイプに、**準備完了としてマーク済み**および**マージ競合**アクションとして[統合されました](https://gitlab.com/gitlab-org/gitlab/-/work_items/602777)。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

トリガーを作成するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**AI** > **トリガー**を選択します。
1. **新しいフロートリガー**を選択します。
1. **説明**に、トリガーの説明を入力します。
1. **Event types**ドロップダウンリストから以下を選択します:
   - 1つ以上の[トリガーイベントタイプ](#trigger-event-types)。
   - トリガーイベントタイプに必要な場合は、トリガーイベントアクション。
1. **サービスアカウント**ドロップダウンリストから、[複合アイデンティティ](../composite_identity.md)となるユーザーを選択します。
1. **設定ソース**で、次のいずれかを選択します:
   - **AIカタログ**: このプロジェクト用に設定されているフローの中から、トリガーで実行するフローを選択します。
   - **設定パス**: フロー設定ファイルのパスを入力します（例: `.gitlab/duo/flows/claude.yaml`）。このオプションを表示するには、`ai_catalog_create_third_party_flows`フラグを有効にする必要があります。
1. **フロートリガーを作成**を選択します。

作成したトリガーが、**AI** > **トリガー**に表示されるようになります。

### トリガーイベントタイプ {#trigger-event-types}

| 名前            | 説明                                                                           | 構成 |
|-----------------|---------------------------------------------------------------------------------------|------|
| メンション         | イシューまたはマージリクエストのコメントでサービスアカウントユーザーがメンションされたとき。 | なし |
| 割り当て          | サービスアカウントユーザーがイシューまたはマージリクエストに割り当てられたとき。               | なし |
| レビュアーの割り当て | サービスアカウントユーザーがレビュアーとしてマージリクエストに割り当てられたとき。           | なし |
| パイプラインイベント | パイプラインのステータスが変更されたとき。                                                        | **トリガータイミング**ドロップダウンリストから、以下を1つ以上選択します:<br>- **実行中**<br>- **成功**<br>- **失敗**<br>- **キャンセル済み** |
| マージリクエスト   | 選択したマージリクエストアクションが発生したとき。                                          | **トリガータイミング**ドロップダウンリストから、以下を1つ選択します:<br>- **承認済み**: マージリクエストに必要なすべての承認がある場合<br>- **準備完了としてマーク済み**: ドラフトのマージリクエストがレビューの準備完了としてマークされた場合<br>- **マージ競合**: マージリクエストが、コードの競合によりマージできなくなった場合 |
| 作業アイテム       | 選択した作業アイテムアクションが発生したとき。                                              | **トリガータイミング**ドロップダウンリストから、以下を1つ選択します:<br>- **作成日**: 作業アイテムが作成された場合<br>- **ステータス変更**: 作業アイテムのステータスが変更された場合 |

## トリガーを編集する {#edit-a-trigger}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**AI** > **トリガー**を選択します。
1. 変更するトリガーで、**フロートリガーを編集**（{{< icon name="pencil" >}}）を選択します。
1. 変更を加えて、**変更を保存**を選択します。

## トリガーを削除する {#delete-a-trigger}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**AI** > **トリガー**を選択します。
1. 変更するトリガーで、**フロートリガーを削除**（{{< icon name="remove" >}}）を選択します。
1. 確認ダイアログで、**OK**を選択します。
