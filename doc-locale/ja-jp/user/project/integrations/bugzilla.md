---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Bugzilla
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Bugzilla](https://www.bugzilla.org/)は、ウェブベースの汎用バグ追跡システムおよびテストツールです。

GitLabで[外部イシュートラッカー](../../../integration/external-issue-tracker.md)としてBugzillaを設定できます。

プロジェクトでBugzillaインテグレーションを有効にするには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **Bugzilla**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
1. 必要なフィールドに入力してください:

   - **プロジェクトのURL**: BugzillaのプロジェクトのURL。たとえば、「Fire Tanuki」という名前の製品の場合: `https://bugzilla.example.org/describecomponents.cgi?product=Fire+Tanuki`。
   - **イシューのURL**: Bugzillaプロジェクトでイシューを表示するためのURL。URLには`:id`が含まれている必要があります。GitLabは`:id`をイシュー番号に置き換えます（たとえば、`https://bugzilla.example.org/show_bug.cgi?id=:id`は`https://bugzilla.example.org/show_bug.cgi?id=123`になります）。
   - **新しいイシューのURL**: リンクされたBugzillaプロジェクトで新しいイシューを作成するためのURL。たとえば、「My Cool App」という名前のプロジェクトの場合: `https://bugzilla.example.org/enter_bug.cgi#h=dupes%7CMy+Cool+App`。

1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

Bugzillaを設定して有効にすると、GitLabプロジェクトページにリンクが表示されます。このリンクをクリックすると、該当するBugzillaプロジェクトに移動します。

このプロジェクトで[GitLab内部イシュートラッキング](../issues/_index.md)を無効にすることもできます。GitLabイシューを無効にする手順と結果の詳細については、プロジェクトの[表示レベル](../../public_access.md#change-project-visibility) 、[機能、および権限](../settings/_index.md#configure-project-features-and-permissions)の構成を参照してください。

## GitLabでBugzillaイシューを参照する {#reference-bugzilla-issues-in-gitlab}

Bugzillaのイシューは、以下を使用して参照できます:

- `#<ID>`。ここで、`<ID>`は数値です（例: `#143`）。
- `<PROJECT>-<ID>`（例: `API_32-143`）。ここで: 
  - `<PROJECT>`は大文字で始まり、その後に大文字、数字、またはアンダースコアが続きます。
  - `<ID>`は数値です。

`<PROJECT>`部分はリンクでは無視されます。リンクは常に**イシューのURL**で指定されたアドレスを指します。

内部イシュートラッカーと外部イシュートラッカーの両方を有効にしている場合は、より長い形式（`<PROJECT>-<ID>`）を使用することをお勧めします。短い形式を使用し、同じIDのイシューが内部イシュートラッカーに存在する場合、内部イシューがリンクされます。

## トラブルシューティング {#troubleshooting}

最近のインテグレーションWebhook配信については、インテグレーションWebhookログを確認してください。
