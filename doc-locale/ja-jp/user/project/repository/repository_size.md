---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Gitリポジトリストレージを削減するためのリポジトリサイズの計算、制限、および方法について説明します。
title: リポジトリサイズ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Gitリポジトリのサイズは、パフォーマンスとストレージコストに大きく影響する可能性があります。圧縮、ハウスキーピング、その他の要因により、インスタンスごとに若干異なる場合があります。

## サイズの計算 {#size-calculation}

プロジェクトの概要ページには、リポジトリファイル、アーティファクト、LFSなど、リポジトリ内のすべてのファイルのサイズが表示されます。このサイズは15分ごとに更新されます。

リポジトリのサイズは、リポジトリ内のすべてのファイルの累積サイズを計算することによって決定されます。この計算は、リポジトリの[ハッシュ](../../../administration/repository_storage_paths.md)化されたストレージパスで`du --summarize --bytes`を実行するのと似ています。

## サイズとストレージの制限 {#size-and-storage-limits}

管理者は、GitLab Self-Managedの[リポジトリサイズ制限](../../../administration/settings/account_and_limit_settings.md#repository-size-limit)を設定できます。GitLab SaaSの場合、サイズ制限は[事前定義](../../gitlab_com/_index.md#account-and-limit-settings)されています。

プロジェクトがサイズ制限に達すると、プッシュ、マージリクエストの作成、LFSオブジェクトのアップロードなどの特定のオペレーションが制限されます。

## リポジトリサイズを削減する方法 {#methods-to-reduce-repository-size}

リポジトリのサイズを削減するには、次の方法を使用できます:

- [履歴からファイルをパージ](#purge-files-from-repository-history): Gitの履歴全体から大きなファイルを削除します。
- [リポジトリのクリーンアップ](#clean-up-repository): 内部Git参照と参照されていないオブジェクトを削除します。
- [blobを消去する](#remove-blobs): 機密情報または秘密情報を含むblobを完全に消去します。

リポジトリのサイズを小さくする前に、[リポジトリの完全バックアップを作成する](../../../administration/backup_restore/_index.md)必要があります。これらの方法は元に戻すことができず、プロジェクトの履歴とデータに影響を与える可能性があります。

利用可能な方法でリポジトリのサイズを小さくする場合、プロジェクトへのアクセスをブロックする必要はありません。プロジェクトがユーザーにアクセス可能な状態のまま、これらのオペレーションを実行できます。これらの方法には、既知のパフォーマンスへの影響はなく、ダウンタイムも発生しません。ただし、ユーザーへの影響を最小限に抑えるために、アクティビティーの低い期間中にこれらのアクションを実行する必要があります。

### リポジトリの履歴からファイルをパージ {#purge-files-from-repository-history}

[`git filter-repo`を使用してファイルをパージして、Gitの履歴から大きなファイルを削除できます。](../../../topics/git/repository.md#purge-files-from-repository-history)パスワードやキーなどの機密データを削除するために、この方法を使用しないでください。代わりに、[blobを消去する](#remove-blobs)を使用してください。

このプロセス:

- Gitの履歴全体を変更します。
- オープンマージリクエストに影響を与える可能性があります。
- 既存のパイプラインに影響を与える可能性があります。
- ローカルリポジトリの再クローンが必要です。
- LFSオブジェクトには影響しません。
- コミット署名を指定しません。
- 元に戻すことはできません。

{{< alert type="note" >}}

ファイルの内容を含むコミットに関する情報は、データベースにキャッシュされ、リポジトリから削除された後でも表示されたままになります。

{{< /alert >}}

### リポジトリのクリーンアップ {#clean-up-repository}

このメソッドを使用して、リポジトリから内部Git参照と参照されていないオブジェクトを削除します。機密データを削除するために、この方法を使用しないでください。代わりに、[blobを消去する](#remove-blobs)を使用してください。

このプロセス:

- `git gc --prune=30.minutes.ago`を実行して、参照されていないオブジェクトを削除します。
- 未使用のLFSオブジェクトのリンクを解除し、ストレージ容量を解放します。
- ディスク上のリポジトリサイズを再計算します。
- 元に戻すことはできません。

{{< alert type="warning" >}}

内部Git参照を削除すると、関連付けられているマージリクエストコミット、パイプライン、および変更の詳細を使用できなくなります。

{{< /alert >}}

前提要件:

- 削除するオブジェクトのリスト。[`git filter-repo`](https://github.com/newren/git-filter-repo)を使用して、`commit-map`ファイル内のオブジェクトのリストを作成します。

リポジトリをクリーンアップするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**に移動します。
1. **リポジトリの保守**を展開します。
1. 削除するオブジェクトのリストをアップロードします。たとえば、`filter-repo`ディレクトリ内の`commit-map`ファイルなどです。

   `commit-map`ファイルが大きすぎると、バックグラウンドのクリーンアッププロセスがタイムアウトして失敗する可能性があります。その結果、リポジトリのサイズは期待どおりに縮小されません。これに対処するには、ファイルを分割して、パーツごとにアップロードします。`20000`から開始し、必要に応じて減らします。次に例を示します:

   ```shell
   split -l 20000 filter-repo/commit-map filter-repo/commit-map-
   ```

1. **クリーンアップ開始**を選択します。

クリーンアップが完了すると、GitLabは再計算されたリポジトリサイズを含むメール通知を送信します。

### blobを消去する {#remove-blobs}

{{< history >}}

- GitLab 17.1で`rewrite_history_ui`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/450701)されました。デフォルトでは無効になっています。
- GitLab 17.2の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/462999)になりました。
- GitLab 17.3の[GitLab Self-ManagedおよびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/462999)になりました。
- GitLab 17.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/472018)になりました。機能フラグ`rewrite_history_ui`は削除されました。

{{< /history >}}

Gitバイナリラージオブジェクト（blob）は、メタデータなしでファイルの内容を格納します。各blobには、リポジトリ内のファイルの特定のバージョンを表す一意のSHAハッシュがあります。

このメソッドを使用して、機密情報または秘密情報を含むblobを完全に消去します。

このプロセス:

- Gitの履歴を書き換えます。
- コミット署名をドロップします。
- 開いているマージリクエストがマージに失敗し、手動でのリベースが必要になる場合があります。
- 古いコミットSHAを参照するパイプラインが中断する可能性があります。
- 古いコミット履歴に基づいた履歴タグとブランチに影響を与える可能性があります。
- ローカルリポジトリの再クローンが必要です。
- 元に戻すことはできません。

{{< alert type="note" >}}

文字列を`***REMOVED***`に置き換えるには、[情報を削除する](../../../topics/git/undo.md#redact-information)を参照してください。

{{< /alert >}}

前提要件:

- プロジェクトのオーナーのロールを持っている必要があります。
- 削除する[オブジェクトIDのリスト](#get-a-list-of-object-ids)。
- プロジェクトは以下であってはなりません:
  - パブリックアップストリームプロジェクトのフォーク。
  - ダウンストリームフォークを含むパブリックアップストリームプロジェクト。

{{< alert type="note" >}}

blobの消去を確実に行うには、処理中にリポジトリへのアクセスを一時的に制限することを検討してください。blobの消去中に新しいコミットがプッシュされると、操作が失敗する可能性があります。

{{< /alert >}}

リポジトリからblobを消去するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **リポジトリの保守**を展開します。
1. **blobを消去する**するを選択します。
1. 消去するblob IDのリストを入力します。各IDは独自の行に入力します。
1. **blobを消去する**するを選択します。
1. 確認ダイアログで、プロジェクトパスを入力します。
1. **はい、blobを消去します**を選択します。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **高度な設定**というラベルが付いたセクションを展開します。
1. **ハウスキーピングを実行**を選択します。操作が完了するまで、少なくとも30分待ちます。
1. 同じ**設定** > **一般** > **高度な設定**セクションで、**到達不能オブジェクトを排除する**を選択します。この操作が完了するまで約5〜10分かかります。

{{< alert type="note" >}}

機密情報を含むプロジェクトがフォークされている場合、ハウスキーピングタスクはこのプロセスを完了せずに成功する可能性があります。ハウスキーピングは、フォークされたデータを含む[特別なオブジェクトプールリポジトリ](../../../administration/housekeeping.md#object-pool-repositories)の整合性を保持する必要があります。サポートが必要な場合は、GitLabサポートにお問い合わせください。

{{< /alert >}}

#### オブジェクトIDのリストを取得する {#get-a-list-of-object-ids}

blobを消去するには、消去するオブジェクトのリストが必要です。これらのIDを取得するには、`ls-tree`コマンドを使用するか、[リポジトリAPIリポジトリツリーのリスト](../../../api/repositories.md#list-repository-tree)エンドポイントを使用します。次の手順では、`ls-tree`コマンドを使用します。

前提要件:

- リポジトリをローカルマシンに複製する必要があります。

特定のコミットまたはブランチにあるblobのリストをサイズでソートして取得するには:

1. ターミナルを開き、リポジトリディレクトリに移動します。
1. 次のコマンドを実行します:

   ```shell
   git ls-tree -r -t --long --full-name <COMMIT/BRANCH> | sort -nk 4
   ```

   出力例:

   ```plaintext
   100644 blob 8150ee86f923548d376459b29afecbe8495514e9  133508 doc/howto/img/remote-development-new-workspace-button.png
   100644 blob cde4360b3d3ee4f4c04c998d43cfaaf586f09740  214231 doc/howto/img/dependency_proxy_macos_config_new.png
   100644 blob 2ad0e839a709e73a6174e78321e87021b20be445  216452 doc/howto/img/gdk-in-gitpod.jpg
   100644 blob 115dd03fc0828a9011f012abbc58746f7c587a05  242304 doc/howto/img/gitpod-button-repository.jpg
   100644 blob c41ebb321a6a99f68ee6c353dd0ed29f52c1dc80  491158 doc/howto/img/dependency_proxy_macos_config.png
   ```

   出力の3番目の列は、blobのオブジェクトIDです。例: `8150ee86f923548d376459b29afecbe8495514e9`。

## トラブルシューティング {#troubleshooting}

### GUIに表示されるリポジトリの統計情報が正しくない {#incorrect-repository-statistics-shown-in-the-gui}

GitLabインターフェースに表示されるリポジトリサイズまたはコミット番号が、エクスポートされた`.tar.gz`またはローカルリポジトリと異なる場合は、次のようにします:

1. GitLab管理者に、Railsコンソールを使用して強制的に更新するように依頼してください。
1. 管理者は次のコマンドを実行する必要があります:

   ```ruby
   p = Project.find_by_full_path('<namespace>/<project>')
   p.statistics.refresh!
   ```

1. プロジェクトの統計情報をクリアし、再計算をトリガーするには:

   ```ruby
   p.repository.expire_all_method_caches
   UpdateProjectStatisticsWorker.perform_async(p.id, ["commit_count","repository_size","storage_size","lfs_objects_size","container_registry_size"])
   ```

1. アーティファクトの総ストレージスペースを確認するには:

   ```ruby
   builds_with_artifacts = p.builds.with_downloadable_artifacts.all

   artifact_storage = 0
   builds_with_artifacts.find_each do |build|
     artifact_storage += build.artifacts_size
   end

   puts "#{artifact_storage} bytes"
   ```

### クリーンアップ後にスペースが解放されない {#space-not-being-freed-after-cleanup}

リポジトリのクリーンアッププロセスを完了したが、ストレージの使用量が変更されない場合:

- 到達不能オブジェクトは、2週間の猶予期間リポジトリに残ることに注意してください。
- これらのオブジェクトはエクスポートには含まれませんが、ファイルシステムスペースを占有します。
- 2週間後、これらのオブジェクトは自動的に削除され、ストレージ使用量の統計が更新されます。
- このプロセスを迅速化するには、管理者に[「到達不能オブジェクトの削除」ハウスキーピングタスク](../../../administration/housekeeping.md)の実行を依頼してください。

### blobが消去されない {#blobs-are-not-removed}

blobが正常に消去されると、GitLabはプロジェクトの監査ログにエントリを追加し、操作を開始した人にメール通知を送信します。

blobの消去が失敗した場合、GitLabは、操作を開始した人に件名が`<project_name> | Project history rewrite failure`のメール通知を送信します。メール本文には、完全なエラーメッセージが含まれています。

考えられるエラーと解決策:

- `validating object ID: invalid object ID`:

  オブジェクトIDリストに構文エラーまたは不正なオブジェクトIDが含まれています。これを解決するには:

    1. [オブジェクトIDリスト](#get-a-list-of-object-ids)を再生成します。
    1. [blob消去手順](#remove-blobs)を再実行します。

- `source repository checksum altered`:

  このエラーは、blob消去プロセス中に誰かがコミットをプッシュすると発生します。これを解決するには:

    1. リポジトリへのすべてのプッシュを一時的にブロックします。
    1. [blob消去手順](#remove-blobs)を再実行します。
    1. プロセスが正常に完了したら、プッシュを再度有効にします。

### リポジトリのサイズ制限に達した {#repository-size-limit-reached}

リポジトリのサイズ制限に達した場合:

- いくつかのデータを削除して、新しいコミットを作成してみてください。
- うまくいかない場合は、一部のblobを[Git LFS](../../../topics/git/lfs/_index.md)に移動するか、履歴から古い依存関係更新を削除することを検討してください。
- それでも変更をプッシュできない場合は、GitLab管理者にお問い合わせいただき、一時的に[プロジェクトの制限を引き上げてください](../../../administration/settings/account_and_limit_settings.md#repository-size-limit)。
- 最後の手段として、新しいプロジェクトを作成し、データを移行します。

{{< alert type="note" >}}

新しいコミットでファイルを削除しても、以前のコミットとblobがまだ存在するため、リポジトリのサイズはすぐには小さくなりません。サイズを効果的に縮小するには、[`git filter-repo`](https://github.com/newren/git-filter-repo)のようなツールを使用して、履歴を書き換える必要があります。

{{< /alert >}}
