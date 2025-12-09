---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループWiki
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

複数のプロジェクトを管理するためにGitLabグループを使用している場合、ドキュメントが複数のグループにまたがる場合があります。すべてのグループメンバーがコントリビュートするための正しいアクセス許可を持つようにするには、[プロジェクト](_index.md)の代わりにグループウィキを作成できます。グループウィキは[プロジェクト](_index.md)と似ていますが、いくつかの制限があります:

- [Git LFS](../../../topics/git/lfs/_index.md)はサポートされていません。
- グループウィキへの変更は、[グループのフィード](../../group/manage.md#group-activity-analytics)には表示されません。

更新については、[プロジェクトとの機能の同等性を追跡するエピック](https://gitlab.com/groups/gitlab-org/-/epics/2782)に従ってください。

プロジェクトと同様に、少なくともデベロッパーロールを持つグループメンバーは、グループウィキを編集できます。グループウィキリポジトリは、[グループリポジトリストレージ移動API](../../../api/group_repository_storage_moves.md)を使用して移動できます。

## グループウィキを表示する {#view-a-group-wiki}

グループウィキにアクセスするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. Wikiを表示するには、次のいずれかの操作を行います:
   - 左側のサイドバーで、**Plan** > **Wiki**を選択します。
   - グループの任意のページで、<kbd>g</kbd>+<kbd>w</kbd> [wikiキーボードショートカット](../../shortcuts.md)を使用します。

## グループウィキをエクスポートする {#export-a-group-wiki}

グループのオーナーロールを持つユーザーは、グループをインポートまたはエクスポートするときに、[グループウィキをインポートまたはエクスポートできます](../settings/import_export.md#migrate-groups-by-uploading-an-export-file-deprecated)。

アカウントがダウングレードされたり、GitLabトライアルが終了したりしても、グループウィキで作成されたコンテンツは削除されません。のグループオーナーがエクスポートされるときは常に、グループウィキデータがエクスポートされます。

機能が利用できなくなった場合に、エクスポートファイルからグループウィキデータにアクセスするには、以下を実行する必要があります:

1. このコマンドで[エクスポートファイルtarball](../settings/import_export.md#migrate-groups-by-uploading-an-export-file-deprecated)を抽出し、`FILENAME`をファイル名に置き換えます: `tar -xvzf FILENAME.tar.gz`
1. `repositories`ディレクトリを参照します。このディレクトリには、拡張子`.wiki.bundle`の[Gitバンドル](https://git-scm.com/docs/git-bundle)が含まれています。
1. Gitバンドルを新しいリポジトリにクローンし、`FILENAME`をバンドルの名前に置き換えます: `git clone FILENAME.wiki.bundle`

内のすべてのファイルは、このGitリポジトリで利用できます。

## グループウィキの表示レベルを設定する {#configure-group-wiki-visibility}

{{< history >}}

- GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/208412)されました。

{{< /history >}}

WikiはGitLabではデフォルトで有効になっています。グループ[管理者](../../permissions.md)は、グループ設定からグループウィキを有効または無効にできます。

グループ設定を開くには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **Wiki**までスクロールして、これらのオプションのいずれかを選択します:
   - **有効**: パブリックグループの場合、すべてのユーザーがにアクセスできます。内部グループの場合、認証済みユーザーのみがにアクセスできます。
   - **プライベート**: グループメンバーのみがにアクセスできます。
   - **無効**: にはアクセスできず、ダウンロードもできません。
1. **変更を保存**を選択します。

## グループウィキの内容を削除する {#delete-the-contents-of-a-group-wiki}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Railsコンソールでグループウィキのコンテンツを削除できます。その後、に新しい入力されたコンテンツを入力できます。

{{< alert type="warning" >}}

この操作は、Wiki内のすべてのデータを削除します。

{{< /alert >}}

{{< alert type="warning" >}}

このコマンドはデータを直接変更するため、正しく実行しないと損害を与える可能性があります。最初にテスト環境でこれらの手順を実行する必要があります。必要に応じてインスタンスを復元できるように、インスタンスのバックアップを準備しておいてください。

{{< /alert >}}

前提要件: 

- 管理者である必要があります。

グループウィキからすべてのデータを削除し、空白の状態で再作成するには:

1. [Railsコンソールセッションを開始します](../../../administration/operations/rails_console.md#starting-a-rails-console-session)。
1. 次のコマンドを実行します:

   ```ruby
   # Enter your group's path
   g = Group.find_by_full_path('<group-name>')

   # This command deletes the wiki group from the filesystem.
   g.wiki.repository.remove

   # Refresh the wiki repository state.
   g.wiki.repository.expire_exists_cache
   ```

Wikiからのすべてのデータがクリアされ、Wikiを使用できるようになりました。

## 関連トピック {#related-topics}

- [管理者向けWiki設定](../../../administration/wikis/_index.md)
- [プロジェクトWiki API](../../../api/wikis.md)
- [グループリポジトリストレージ移動API](../../../api/group_repository_storage_moves.md)
- [グループWiki API](../../../api/group_wikis.md)
- [Wikiキーボードショートカット](../../shortcuts.md#wiki-pages)
- [エピック: プロジェクトとの機能の同等性](https://gitlab.com/groups/gitlab-org/-/epics/2782)
