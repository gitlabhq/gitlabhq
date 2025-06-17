---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Fork a Git repository when you want to contribute changes back to an upstream repository you don't have permission to contribute to directly.
title: フォーク
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

フォークとは、別の Gitリポジトリの個人用コピーであり、選択したネームスペースに配置されます。コピーには、すべてのブランチ、tag、CI/CD ジョブ設定など、アップストリームリポジトリのコンテンツが含まれています。フォークからマージリクエストを作成して、アップストリームリポジトリをターゲットにすることができます。個々のコミットをフォークからアップストリームリポジトリに[cherry-pick](../merge_requests/cherry_pick_changes.md)することもできます。

元のリポジトリへの書き込みアクセス権がある場合、フォークは必要ありません。代わりに、ブランチを使用して作業を管理します。コントリビュートしたいリポジトリへの書き込みアクセス権がない場合は、フォークしてください。フォークに変更を加え、マージリクエストを通じてアップストリームリポジトリに送信します。

[機密マージリクエスト](../merge_requests/confidential.md)を作成するには、公開リポジトリの個人用フォークを使用します。

## フォークを作成

{{< history >}}

- GitLab 16.6 [で導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/24894)。

{{< /history >}}

GitLab で既存のプロジェクトをフォークするには:

1. プロジェクトのホームページの右上隅で、**フォーク** ({{< icon name="fork" >}}) を選択します。
1. 任意。**プロジェクト名**を編集します。
1. **プロジェクトURL**で、フォークの所属先の[ネームスペース](../../namespace/_index.md)を選択します。
1. **プロジェクト slug** を追加します。この値は、フォークへの URL の一部になります。ネームスペース内で一意である必要があります。
1. 任意。**プロジェクトの説明**を追加します。
1. **含めるブランチ**オプションのいずれかを選択します。
   - **すべてのブランチ** (デフォルト)。
   - **デフォルトブランチのみ**。`--single-branch`および`--no-tags`[Git オプション](https://git-scm.com/docs/git-clone)を使用します。
1. フォークの**表示レベル**を選択します。表示レベルの詳細については、[プロジェクトとグループの表示](../../public_access.md)をお読みください。
1. **プロジェクトをフォークする** を選択します。

GitLab はフォークを作成し、新しいフォークのページにリダイレクトし、フォークの作成を[監査ログ](../../compliance/audit_event_types.md)に記録します。

変更を頻繁にアップストリームにコントリビュートする場合は、フォークの[デフォルトターゲット](../merge_requests/creating_merge_requests.md#set-the-default-target-project)を設定することを検討してください。

## フォークを更新

フォークはアップストリームリポジトリとの同期がずれ、更新が必要になる場合があります:

- **進んでいる**:フォークには、アップストリームリポジトリに存在しない新しいコミットが含まれています。フォークを同期するには、マージリクエストを作成して、変更をアップストリームリポジトリにプッシュします。
- **遅れている**:アップストリームリポジトリには、フォークに存在しない新しいコミットが含まれています。フォークを同期するには、新しいコミットをフォークにプルします。
- **進んでいて、遅れている**:アップストリームリポジトリとフォークの両方に、もう一方に存在しない新しいコミットが含まれています。フォークを完全に同期するには、マージリクエストを作成して変更をプッシュし、アップストリームリポジトリの新しい変更をフォークにプルします。

フォークをそのアップストリームリポジトリと同期するには、GitLab UI またはコマンドラインから更新します。GitLab Premium および Ultimateプランでは、アップストリームリポジトリの[プルミラーとしてフォークを設定](#with-repository-mirroring)して、更新を自動化することもできます。

### UIから

{{< history >}}

- GitLab 15.11で`synchronize_fork`という名前の[フラグ](../../../administration/feature_flags.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/330243)されました。デフォルトでは無効になっていますが、`gitlab-org/gitlab`および`gitlab-com/www-gitlab-com`ネームスペース内のプロジェクトでのみ有効になっています。
- GitLab 16.0 [で一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/330243)になりました。機能フラグ `synchronize_fork` を削除しました。

{{< /history >}}

前提要件:

- アップストリームリポジトリの[保護されていないブランチ](branches/protected.md)からフォークを作成する必要があります。

GitLab UI からフォークを更新するには:

1. 左側のサイドバーで、**検索または移動**を選択します。
1. **すべてのプロジェクトを表示**を選択します。
1. 更新するフォークを選択します。
1. ブランチ名のドロップダウンリストの下にある**フォーク元** ({{< icon name="fork" >}}) 情報ボックスで、フォークが進んでいるか、遅れているか、またはその両方であるかを確認します。この例では、フォークはアップストリームリポジトリよりも遅れています:

   ![アップストリームリポジトリより数コミット遅れているフォークの情報ボックス](img/update-fork_v16_6.png)

1. フォークがアップストリームリポジトリよりも**進んでいる**場合は、**マージリクエストを作成**を選択して、フォークの変更をアップストリームリポジトリに追加することを提案します。
1. フォークがアップストリームリポジトリよりも**遅れている**場合は、**フォークを更新**を選択して、アップストリームリポジトリから変更をプルします。
1. フォークがアップストリームリポジトリよりも**進んでいて、遅れている**場合、GitLab がマージコンフリクトを検出しない場合にのみ、UI から更新できます:
   - フォークにマージコンフリクトが含まれていない場合は、**マージリクエストを作成** を選択して、フォークの変更をアップストリームリポジトリにプッシュすること、**フォークを更新** して変更をフォークにプルすること、またはその両方を行うことを提案できます。フォーク内の変更のタイプによって、どの操作が適切かが決まります。
   - フォークにマージコンフリクトが含まれている場合、GitLab はコマンドラインからフォークを更新するための段階的なガイドを表示します。

### コマンドラインから

コマンドラインからフォークを更新することもできます。

前提要件:

- ローカルマシンに[Git クライアントをダウンロードしてインストール](../../../topics/git/how_to_install_git/_index.md)する必要があります。
- 更新するリポジトリの[フォークを作成](#create-a-fork)する必要があります。

コマンドラインからフォークを更新するには、[Git を使用してフォークを更新する](../../../topics/git/forks.md)の手順に従ってください。

### リポジトリのミラーリングを使用

{{< details >}}

- プラン:Premium、Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

次のすべての条件が満たされている場合、フォークはアップストリームのミラーとして Configure できます:

1. サブスクリプションが**Premium**または**Ultimate**である。
1. すべての変更をブランチ (`main` ではない) で作成します。
1. [機密イシューのマージリクエスト](../merge_requests/confidential.md)では作業しないでください。これには、`main`への変更が必要です。

[リポジトリのミラーリング](mirror/_index.md)は、フォークを元のリポジトリと同期した状態に保ちます。この方法では、手動で `git pull` を実行する必要はなく、1 時間に 1 回フォークが更新されます。手順については、[プルミラーリングの Configure ](mirror/pull.md#configure-pull-mirroring)をお読みください。

{{< alert type="warning" >}}

ミラーリングでは、マージリクエストを承認する前に、同期を求められます。自動化する必要があります。

{{< /alert >}}

## 変更をアップストリームにマージ

コードをアップストリームリポジトリに送り返す準備ができたら、[フォークで作業する場合](../merge_requests/creating_merge_requests.md#when-you-work-in-a-fork)の説明に従って、新しいマージリクエストを作成します。正常にマージされると、変更はマージ先のリポジトリとブランチに追加されます。

## フォークのリンクを解除

フォーク関係を削除すると、フォークとそのアップストリームリポジトリとのリンクが解除されます。フォークはその後、独立したリポジトリになります。

前提要件:

- フォークのリンクを解除するには、プロジェクトオーナーである必要があります。

{{< alert type="warning" >}}

フォーク関係を削除すると、ソースにマージリクエストを送信できなくなります。誰かがリポジトリをフォークした場合、そのフォークも関係を失います。フォーク関係を復元するには、[APIを使用](../../../api/project_forks.md#create-a-fork-relationship-between-projects)します。

{{< /alert >}}

フォーク関係を削除するには:

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを見つけます。
1. **設定 > 一般**を選択します。
1. **詳細設定**を展開します。
1. **フォーク関係の削除**セクションで、**フォーク関係の削除**を選択します。
1. 確認するには、プロジェクトパスを入力し、**確認**を選択します。

GitLab は、リンク解除操作を[監査ログ](../../compliance/audit_event_types.md)に記録します。[ハッシュストレージプール](../../../administration/repository_storage_paths.md#hashed-object-pools)を使用して別のリポジトリとオブジェクトを共有するフォークのリンクを解除すると:

- すべてのオブジェクトがプールからフォークにコピーされます。
- コピープロセスが完了すると、ストレージプールからのそれ以上の更新はフォークに反映されません。

## フォークのストレージ使用量を確認

フォークは[重複排除ストラテジ](../../../development/git_object_deduplication.md)を使用して、必要なストレージスペースを削減します。フォークは、ソースリポジトリに接続されているオブジェクトプールにアクセスできます。

詳細およびストレージの使用状況の確認については、[プロジェクトフォークストレージの使用状況を表示](../../storage_usage_quotas.md#view-project-fork-storage-usage)を参照してください。

## 関連トピック

- GitLab コミュニティフォーラム:[フォークの更新](https://forum.gitlab.com/t/refreshing-a-fork/32469)
- [グループ外でのプロジェクトのフォークを防止](../../group/access_and_permissions.md#prevent-project-forking-outside-group)
- [Git LFS がフォークでどのように動作するかを理解する](../../../topics/git/lfs/_index.md#understand-how-git-lfs-works-with-forks)

## トラブルシューティング

### エラー: `An error occurred while forking the project. Please try again`

このエラーは、フォークされたプロジェクトと新しいネームスペースの間でインスタンスRunnerの設定が一致しないことが原因である可能性があります。詳細については、Runner ドキュメントの[フォーク](../../../ci/runners/configure_runners.md#using-instance-runners-in-forked-projects)を参照してください。

### フォーク関係の削除に失敗する

UI または API を使用してフォークを削除できない場合は、[Railsコンソールセッション](../../../administration/operations/rails_console.md#starting-a-rails-console-session)でフォーク関係の削除を試みることができます:

```ruby
p = Project.find_by_full_path('<project_path>')
u = User.find_by_username('<username>')
Projects::UnlinkForkService.new(p, u).execute
```
