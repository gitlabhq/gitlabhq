---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: トリガー
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.3で`ai_flow_triggers`[フラグ](../../../administration/feature_flags/_index.md)とともに導入されました。デフォルトでは有効になっています。
- GitLab 18.8で追加の`ai_catalog_create_third_party_flows`[フラグ](../../../administration/feature_flags/_index.md)が必要になるように[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217634)されました。デフォルトでは無効になっています。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。

{{< /history >}}

> [!flag] この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

トリガーは、フローがいつ実行されるかを決定します。

フローを実行するサービスアカウントと、フローを実行させる条件を指定します。

たとえば、ディスカッションでサービスアカウントにメンションしたとき、またはサービスアカウントをレビュアーとしてアサインしたときに、フローがトリガーされるように指定できます。

## トリガーを作成する {#create-a-trigger}

{{< history >}}

- GitLab 18.5で、**アサイン**イベントタイプと**レビュアーをアサインする**イベントタイプが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/567787)されました。

{{< /history >}}

前提条件: 

- プロジェクトのメンテナーロール以上が必要です。

トリガーを作成するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **自動化** > **トリガー**を選択します。
1. **新しいフロートリガー**を選択します。
1. **説明**に、トリガーの説明を入力します。
1. **イベントタイプ**ドロップダウンリストから、1つ以上のイベントタイプを選択します:
   - **メンション**: イシューまたはマージリクエストのコメントでサービスアカウントユーザーがメンションされたとき。
   - **アサイン**: サービスアカウントユーザーがイシューまたはマージリクエストにアサインされたとき。
   - **レビュアーをアサインする**: サービスアカウントユーザーがレビュアーとしてマージリクエストにアサインされたとき。
1. **サービスアカウントユーザー**ドロップダウンリストから、サービスアカウントユーザーを選択します。
1. **設定ソース**で、次のいずれかを選択します:
   - **AIカタログ**: このプロジェクト用に設定されているフローの中から、トリガーで実行するフローを選択します。
   - **設定パス**: フロー設定ファイルのパスを入力します（例: `.gitlab/duo/flows/claude.yaml`）。
1. **フロートリガーを作成**を選択します。

作成したトリガーが、**自動化** > **トリガー**に表示されるようになります。

### トリガーを編集する {#edit-a-trigger}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **自動化** > **トリガー**を選択します。
1. 変更するトリガーで、**フロートリガーを編集**（{{< icon name="pencil" >}}）を選択します。
1. 変更を加えて、**変更を保存**を選択します。

### トリガーを削除する {#delete-a-trigger}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **自動化** > **トリガー**を選択します。
1. 変更するトリガーで、**フロートリガーを削除**（{{< icon name="remove" >}}）を選択します。
1. 確認ダイアログで、**OK**を選択します。
