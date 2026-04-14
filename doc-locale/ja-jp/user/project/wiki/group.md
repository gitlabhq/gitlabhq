---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループWiki
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

複数のプロジェクトを管理するためにGitLabグループを使用している場合、ドキュメントが複数のグループにまたがる可能性があります。すべてのグループメンバーがコントリビュートするための適切なアクセス権限を持つように、[プロジェクトウィキ](_index.md)の代わりにグループウィキを作成できます。グループウィキは[プロジェクトウィキ](_index.md)に似ていますが、いくつかの制限があります:

- [Git LFS](../../../topics/git/lfs/_index.md)はサポートされていません。
- グループウィキへの変更は、[グループのアクティビティフィード](../../group/manage.md#group-activity-analytics)には表示されません。

更新については、[プロジェクトウィキとの機能の同等性を追跡するエピック](https://gitlab.com/groups/gitlab-org/-/epics/2782)を参照してください。

プロジェクトウィキと同様に、デベロッパー、メンテナー、またはオーナーロールを持つグループメンバーはグループウィキを編集できます。グループウィキリポジトリは、[グループリポジトリストレージ移動API](../../../api/group_repository_storage_moves.md)を使用して移動できます。

## グループウィキを表示する {#view-a-group-wiki}

グループウィキにアクセスするには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. Wikiを表示するには、次のいずれかの操作を行います。
   - 左サイドバーで、**Plan** > **Wiki**を選択します。
   - グループ内の任意のページで、<kbd>g</kbd>+<kbd>w</kbd> [Wikiキーボードショートカット](../../shortcuts.md)を使用します。

## グループウィキをエクスポートする {#export-a-group-wiki}

グループ内でオーナーロールを持つユーザーは、グループをインポートまたはエクスポートする際に、[グループウィキをインポートまたはエクスポートする](../settings/import_export.md#migrate-groups-by-uploading-an-export-file-deprecated)ことができます。

グループウィキで作成されたコンテンツは、アカウントがロールバックされたり、GitLabのトライアルが終了しても削除されません。グループウィキのデータは、Wikiのグループオーナーがエクスポートされるたびにエクスポートされます。

機能が利用できなくなった場合に、エクスポートファイルからグループウィキデータにアクセスするには、次の手順を実行します:

1. `FILENAME`をファイル名に置き換え、このコマンドで[エクスポートファイルのターボール](../settings/import_export.md#migrate-groups-by-uploading-an-export-file-deprecated)を展開します: `tar -xvzf FILENAME.tar.gz`
1. `repositories`ディレクトリに移動します。このディレクトリには、拡張子`.wiki.bundle`を持つ[Gitバンドル](https://git-scm.com/docs/git-bundle)が含まれています。
1. 新しいリポジトリにGitバンドルをクローンし、`FILENAME`をバンドル名に置き換えます: `git clone FILENAME.wiki.bundle`

Wiki内のすべてのファイルは、このGitリポジトリで利用できます。

## グループウィキの表示レベルを設定する {#configure-group-wiki-visibility}

WikiはGitLabではデフォルトで有効になっています。グループ[管理者](../../permissions.md)は、グループ設定を通じてグループウィキを有効または無効にできます。

グループ設定を開くには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **Wiki**までスクロールし、以下のいずれかのオプションを選択します:
   - **有効**: 公開グループの場合、誰でもWikiにアクセスできます。内部グループの場合、認証済みユーザーのみがWikiにアクセスできます。
   - **非公開**: グループメンバーのみがWikiにアクセスできます。
   - **無効**: Wikiはアクセスできず、ダウンロードもできません。
1. **変更を保存**を選択します。

## グループウィキのコンテンツを削除する {#delete-the-contents-of-a-group-wiki}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

> [!warning]
> この操作により、Wiki内のすべてのデータが削除されます。

Railsコンソールを使用してグループウィキのコンテンツを削除できます。その後、新しいコンテンツをWikiに投入できます。

> [!warning]
> このコマンドはデータを直接変更するため、正しく実行しないと損害を与える可能性があります。まず、テスト環境でこれらの手順を実行する必要があります。インスタンスのバックアップを準備しておき、必要に応じてインスタンスを復元することができます。

前提条件: 

- 管理者である必要があります。

グループウィキからすべてのデータを削除し、空白の状態で再作成するには:

1. [Railsコンソールセッション](../../../administration/operations/rails_console.md#starting-a-rails-console-session)を開始します。
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
- [エピック: プロジェクトウィキとの機能の同等性](https://gitlab.com/groups/gitlab-org/-/epics/2782)
