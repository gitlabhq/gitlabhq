---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: トリガー
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise。
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- `ai_flow_triggers`[フラグ](../../../administration/feature_flags/_index.md)とともにGitLab 18.3で導入されました。デフォルトでは有効になっています。

{{< /history >}}

トリガーは、フローがいつ実行されるかを決定します。

フローを実行するサービスアカウントと、フローを実行させる条件を指定します。

たとえば、ディスカッションでサービスアカウントにメンションした場合や、サービスアカウントをレビュアーとしてアサインした場合にトリガーされるように、フローを指定できます。

## トリガーを作成する {#create-a-trigger}

{{< history >}}

- **アサイン**イベントタイプと**レビュアーをアサインする**イベントタイプがGitLab 18.5で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/567787)。

{{< /history >}}

前提要件:

- プロジェクトのメンテナーロール以上が必要です。

トリガーを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **自動化** > **トリガー**を選択します。
1. **New flow trigger**（新しいフロートリガー）を選択します。
1. **説明**に、トリガーの説明を入力します。
1. **イベントタイプ**ドロップダウンリストから、1つ以上のイベントタイプを選択します:
   - **メンション**: イシューまたはマージリクエストのコメントでサービスアカウントユーザーがメンションされた場合。
   - **アサイン**: サービスアカウントユーザーがイシューまたはマージリクエストにアサインされた場合。
   - **レビュアーをアサインする**: サービスアカウントユーザーがマージリクエストのレビュアーとしてアサインされた場合。
1. **サービスアカウントユーザー**ドロップダウンリストから、サービスアカウントユーザーを選択します。
1. **設定ソース**で、次のいずれかを選択します:
   - **AIカタログ**: このプロジェクト用に設定されたフローから、実行するトリガーのフローを選択します。
   - **設定パス**: フロー設定ファイルへのパスを入力します（例：`.gitlab/duo/flows/claude.yaml`）。
1. **Create flow trigger**（フロートリガーを作成）を選択します。

トリガーが**自動化** > **トリガー**に表示されるようになりました。

### トリガーを編集 {#edit-a-trigger}

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **自動化** > **トリガー**を選択します。
1. 変更するトリガーで、**Edit flow trigger**（フロートリガーを編集）（{{< icon name="pencil" >}}）を選択します。
1. 変更を加えて、**変更を保存**を選択します。

### トリガーを削除 {#delete-a-trigger}

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **自動化** > **トリガー**を選択します。
1. 変更するトリガーで、**Delete flow trigger**（フロートリガーを削除）（{{< icon name="remove" >}}）を選択します。
1. 確認ダイアログで、**OK**を選択します。
