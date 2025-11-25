---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Markdownキャッシュ
description: Markdownキャッシュを無効にします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

パフォーマンス上の理由から、GitLabでは、次のようなフィールドのMarkdownテキストのHTMLバージョンをキャッシュします:

- コメント
- イシューの説明。
- マージリクエストの説明。

これらのキャッシュされたバージョンは、`external_url`設定オプションが変更された場合などに、古くなる可能性があります。キャッシュされたテキスト内のリンクは、古いURLを参照したままになります。

## キャッシュを無効にする {#invalidate-the-cache}

APIまたはRailsコンソールを使用して、Markdownキャッシュを無効にすることができます。

### APIを使用する {#use-the-api}

前提要件: 

- 管理者アクセス権が必要です。

APIを使用して既存のキャッシュを無効にするには、次のようにします:

1. PUTリクエストを送信して、アプリケーション設定の`local_markdown_version`設定を増やします:

   ```shell
   curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/application/settings?local_markdown_version=<increased_number>"
   ```

このAPIエンドポイントの詳細については、[アプリケーション設定の更新](../api/settings.md#update-application-settings)を参照してください。

### Railsコンソールを使用 {#use-the-rails-console}

前提要件: 

- [Railsコンソール](operations/rails_console.md)にアクセスできる必要があります。

#### グループの場合 {#for-a-group}

グループのキャッシュを無効にするには、次のようにします:

1. Railsコンソールを起動します:

   ```shell
   sudo gitlab-rails console
   ```

1. 更新するグループを見つけます:

   ```ruby
   group = Group.find(<group_id>)
   ```

1. グループ内のすべてのプロジェクトのキャッシュを無効にします:

   ```ruby
   group.all_projects.each_slice(10) do |projects|
     projects.each do |project|
       # Invalidate issues
       project.issues.update_all(
         description_html: nil,
         title_html: nil
       )

       # Invalidate merge requests
       project.merge_requests.update_all(
         description_html: nil,
         title_html: nil
       )

       # Invalidate notes/comments
       project.notes.update_all(note_html: nil)
     end

     # Pause for one second after updating 10 projects
     sleep 1
   end
   ```

#### プロジェクトの場合 {#for-a-project}

単一プロジェクトのキャッシュを無効にするには、次のようにします:

1. Railsコンソールを起動します:

   ```shell
   sudo gitlab-rails console
   ```

1. 更新するプロジェクトを見つけます:

   ```ruby
   project = Project.find(<project_id>)
   ```

1. イシューを無効にします:

   ```ruby
   project.issues.update_all(
     description_html: nil,
     title_html: nil
   )
   ```

1. マージリクエストを無効にします:

   ```ruby
   project.merge_requests.update_all(
     description_html: nil,
     title_html: nil
   )
   ```

1. 注釈とコメントを無効にします:

   ```ruby
   project.notes.update_all(note_html: nil)
   ```
