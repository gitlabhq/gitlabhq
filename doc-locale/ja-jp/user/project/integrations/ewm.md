---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Engineering Workflow Management（EWM）
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

EWMインテグレーションを使用すると、GitLabから、マージリクエストの説明とコミットメッセージで言及されているEWM作業アイテムに移動できます。各作業アイテムの参照は、作業アイテムへのリンクに自動的に変換されます。

このIBM製品は、[以前はRational Team Concert（RTC）という名前でした](https://jazz.net/blog/index.php/2019/04/23/renaming-the-ibm-continuous-engineering-portfolio/)。このインテグレーションは、RTCとEWMのすべてのバージョンと互換性があります。

EWMインテグレーションを有効にするには、プロジェクトで次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **EWM**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
1. 必要なフィールドに入力してください:

   - **プロジェクトのURL**: EWMプロジェクトエリアのURL。

     プロジェクトエリアのURLを取得するには、`/ccm/web/projects`パスに移動して、一覧表示されているプロジェクトのURLをコピーします。たとえば`https://example.com/ccm/web/Example%20Project`などです。
   - **イシューのURL**: EWMプロジェクトエリア内の作業アイテムエディタへのURL。

     形式は`<your-server-url>/resource/itemName/com.ibm.team.workitem.WorkItem/:id`です。GitLabは`:id`をイシュー番号に置き換えます（たとえば、`https://example.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/:id`は`https://example.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/123`になります）。
   - **新しいイシューのURL**: EWMプロジェクトエリアに新しい作業アイテムを作成するためのURL。

     プロジェクトエリアのURLに次のフラグメントを追加します: `#action=com.ibm.team.workitem.newWorkItem`。たとえば`https://example.com/ccm/web/projects/JKE%20Banking#action=com.ibm.team.workitem.newWorkItem`などです。

1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

## コミットメッセージでEWM作業アイテムを参照 {#reference-ewm-work-items-in-commit-messages}

作業アイテムを参照するには、EWM Gitインテグレーションツールキットでサポートされている任意のキーワードを使用できます。形式: `<keyword> <id>`。

次のキーワードを使用できます:

- `bug`
- `defect`
- `rtcwi`
- `task`
- `work item`
- `workitem`

キーワード`#`を使用しないでください。詳細については、[Commitコメントからのリンクの作成](https://www.ibm.com/docs/en/elm/7.0.0?topic=commits-creating-links-from-commit-comments)を参照してください。
