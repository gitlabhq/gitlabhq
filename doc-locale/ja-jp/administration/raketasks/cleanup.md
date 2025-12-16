---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Rakeタスクのクリーンアップ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、GitLabインスタンスをクリーンアップするためのRakeタスクを提供します。

## LFSファイルの未参照の削除 {#remove-unreferenced-lfs-files}

{{< alert type="warning" >}}

GitLabのアップグレード後12時間以内にこれを実行しないでください。これは、すべてのバックグラウンド移行が完了していることを確認するためです。そうしないと、データが失われる可能性があります。

{{< /alert >}}

LFSファイルをリポジトリの履歴から削除すると、それらは孤立し、ディスク容量を消費し続けます。このRakeタスクを使用すると、データベースから無効な参照を削除でき、LFSファイルのガベージコレクションが可能になります。例: 

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake gitlab:cleanup:orphan_lfs_file_references PROJECT_PATH="gitlab-org/gitlab-foss"
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
bundle exec rake gitlab:cleanup:orphan_lfs_file_references RAILS_ENV=production PROJECT_PATH="gitlab-org/gitlab-foss"
```

{{< /tab >}}

{{< /tabs >}}

`PROJECT_PATH`の代わりに`PROJECT_ID`でプロジェクトを指定することもできます。

例: 

```shell
$ sudo gitlab-rake gitlab:cleanup:orphan_lfs_file_references PROJECT_ID="13083"

I, [2019-12-13T16:35:31.764962 #82356]  INFO -- :  Looking for orphan LFS files for project GitLab Org / GitLab Foss
I, [2019-12-13T16:35:31.923659 #82356]  INFO -- :  Removed invalid references: 12
```

デフォルトでは、このタスクは何も削除しませんが、削除できるファイルの参照の数を示します。実際に参照を削除する場合は、`DRY_RUN=false`を指定してコマンドを実行します。削除する参照の数を制限するには、`LIMIT={number}`パラメータを使用することもできます。

このRakeタスクは、LFSファイルへの参照のみを削除します。参照されていないLFSファイルは、（1日に1回）以降にガベージコレクションされます。すぐにガベージコレクションする必要がある場合は、以下で説明する`rake gitlab:cleanup:orphan_lfs_files`を実行します。

### 参照されていないLFSファイルをすぐに削除 {#remove-unreferenced-lfs-files-immediately}

参照されていないLFSファイルは毎日削除されますが、必要に応じてすぐに削除できます。参照されていないLFSファイルをすぐに削除するには、次の手順に従います:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake gitlab:cleanup:orphan_lfs_files
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
bundle exec rake gitlab:cleanup:orphan_lfs_files
```

{{< /tab >}}

{{< /tabs >}}

出力例: 

```shell
$ sudo gitlab-rake gitlab:cleanup:orphan_lfs_files
I, [2020-01-08T20:51:17.148765 #43765]  INFO -- : Removed unreferenced LFS files: 12
```

## プロジェクトのアップロードファイルをクリーンアップ {#clean-up-project-upload-files}

プロジェクトのアップロードファイルがGitLabデータベースに存在しない場合は、それらのファイルをクリーンアップします。

### ファイルシステムからプロジェクトのアップロードファイルをクリーンアップ {#clean-up-project-upload-files-from-file-system}

GitLabデータベースに存在しない場合は、ローカルプロジェクトのアップロードファイルをクリーンアップします。このタスクは、プロジェクトを見つけることができる場合はファイルを修正しようとしますが、それ以外の場合は、ファイルを紛失したディレクトリに移動します。ファイルシステムからプロジェクトのアップロードファイルをクリーンアップするには、次の手順に従います:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake gitlab:cleanup:project_uploads
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
bundle exec rake gitlab:cleanup:project_uploads RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

出力例: 

```shell
$ sudo gitlab-rake gitlab:cleanup:project_uploads

I, [2018-07-27T12:08:27.671559 #89817]  INFO -- : Looking for orphaned project uploads to clean up. Dry run...
D, [2018-07-27T12:08:28.293568 #89817] DEBUG -- : Processing batch of 500 project upload file paths, starting with /opt/gitlab/embedded/service/gitlab-rails/public/uploads/test.out
I, [2018-07-27T12:08:28.689869 #89817]  INFO -- : Can move to lost and found /opt/gitlab/embedded/service/gitlab-rails/public/uploads/test.out -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/-/project-lost-found/test.out
I, [2018-07-27T12:08:28.755624 #89817]  INFO -- : Can fix /opt/gitlab/embedded/service/gitlab-rails/public/uploads/foo/bar/89a0f7b0b97008a4a18cedccfdcd93fb/foo.txt -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/qux/foo/bar/89a0f7b0b97008a4a18cedccfdcd93fb/foo.txt
I, [2018-07-27T12:08:28.760257 #89817]  INFO -- : Can move to lost and found /opt/gitlab/embedded/service/gitlab-rails/public/uploads/foo/bar/1dd6f0f7eefd2acc4c2233f89a0f7b0b/image.png -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/-/project-lost-found/foo/bar/1dd6f0f7eefd2acc4c2233f89a0f7b0b/image.png
I, [2018-07-27T12:08:28.764470 #89817]  INFO -- : To cleanup these files run this command with DRY_RUN=false

$ sudo gitlab-rake gitlab:cleanup:project_uploads DRY_RUN=false
I, [2018-07-27T12:08:32.944414 #89936]  INFO -- : Looking for orphaned project uploads to clean up...
D, [2018-07-27T12:08:33.293568 #89817] DEBUG -- : Processing batch of 500 project upload file paths, starting with /opt/gitlab/embedded/service/gitlab-rails/public/uploads/test.out
I, [2018-07-27T12:08:33.689869 #89817]  INFO -- : Did move to lost and found /opt/gitlab/embedded/service/gitlab-rails/public/uploads/test.out -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/-/project-lost-found/test.out
I, [2018-07-27T12:08:33.755624 #89817]  INFO -- : Did fix /opt/gitlab/embedded/service/gitlab-rails/public/uploads/foo/bar/89a0f7b0b97008a4a18cedccfdcd93fb/foo.txt -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/qux/foo/bar/89a0f7b0b97008a4a18cedccfdcd93fb/foo.txt
I, [2018-07-27T12:08:33.760257 #89817]  INFO -- : Did move to lost and found /opt/gitlab/embedded/service/gitlab-rails/public/uploads/foo/bar/1dd6f0f7eefd2acc4c2233f89a0f7b0b/image.png -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/-/project-lost-found/foo/bar/1dd6f0f7eefd2acc4c2233f89a0f7b0b/image.png
```

オブジェクトストレージを使用している場合は、[オールインワンRakeタスク](uploads/migrate.md#all-in-one-rake-task)を実行して、すべてのアップロードがオブジェクトストレージに移行され、アップロードフォルダーにディスク上のファイルがないことを確認します。

### オブジェクトストレージからプロジェクトのアップロードファイルをクリーンアップ {#clean-up-project-upload-files-from-object-storage}

GitLabデータベースに存在しない場合は、オブジェクトストレージのアップロードファイルを紛失したディレクトリに移動します。オブジェクトストレージからプロジェクトのアップロードファイルをクリーンアップするには、次の手順に従います:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake gitlab:cleanup:remote_upload_files
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
bundle exec rake gitlab:cleanup:remote_upload_files RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

出力例: 

```shell
$ sudo gitlab-rake gitlab:cleanup:remote_upload_files

I, [2018-08-02T10:26:13.995978 #45011]  INFO -- : Looking for orphaned remote uploads to remove. Dry run...
I, [2018-08-02T10:26:14.120400 #45011]  INFO -- : Can be moved to lost and found: @hashed/6b/DSC_6152.JPG
I, [2018-08-02T10:26:14.120482 #45011]  INFO -- : Can be moved to lost and found: @hashed/79/02/7902699be42c8a8e46fbbb4501726517e86b22c56a189f7625a6da49081b2451/711491b29d3eb08837798c4909e2aa4d/DSC00314.jpg
I, [2018-08-02T10:26:14.120634 #45011]  INFO -- : To cleanup these files run this command with DRY_RUN=false
```

```shell
$ sudo gitlab-rake gitlab:cleanup:remote_upload_files DRY_RUN=false

I, [2018-08-02T10:26:47.598424 #45087]  INFO -- : Looking for orphaned remote uploads to remove...
I, [2018-08-02T10:26:47.753131 #45087]  INFO -- : Moved to lost and found: @hashed/6b/DSC_6152.JPG -> lost_and_found/@hashed/6b/DSC_6152.JPG
I, [2018-08-02T10:26:47.764356 #45087]  INFO -- : Moved to lost and found: @hashed/79/02/7902699be42c8a8e46fbbb4501726517e86b22c56a189f7625a6da49081b2451/711491b29d3eb08837798c4909e2aa4d/DSC00314.jpg -> lost_and_found/@hashed/79/02/7902699be42c8a8e46fbbb4501726517e86b22c56a189f7625a6da49081b2451/711491b29d3eb08837798c4909e2aa4d/DSC00314.jpg
```

## 孤立したアーティファクトファイルを削除 {#remove-orphan-artifact-files}

{{< alert type="note" >}}

これらのコマンドは、[オブジェクトストレージ](../object_storage.md)に保存されているアーティファクトでは機能しません。

{{< /alert >}}

ディスク上のジョブアーティファクトファイルまたはディレクトリが多すぎることに気付いた場合は、次を実行できます:

```shell
sudo gitlab-rake gitlab:cleanup:orphan_job_artifact_files
```

このコマンドは、以下を実行します:

- アーティファクトフォルダー全体をスキャンします。
- どのファイルがデータベースに記録されているかを確認します。
- データベースレコードが見つからない場合、ファイルとディレクトリはディスクから削除されます。

デフォルトでは、このタスクは何も削除しませんが、削除できるものを表示します。実際にファイルを削除する場合は、`DRY_RUN=false`を指定してコマンドを実行します:

```shell
sudo gitlab-rake gitlab:cleanup:orphan_job_artifact_files DRY_RUN=false
```

削除するファイルの数を`LIMIT`（デフォルト`100`）で制限することもできます:

```shell
sudo gitlab-rake gitlab:cleanup:orphan_job_artifact_files LIMIT=100
```

これにより、ディスクから最大100個のファイルのみが削除されます。これは、テスト目的で小さなセットを削除するために使用できます。

`DEBUG=1`を指定すると、孤立していると検出されたすべてのファイルのフルパスが表示されます。

`ionice`がインストールされている場合、タスクはそれを使用して、コマンドがディスクに過度の負荷をかけていないことを確認します。`NICENESS`を使用してnicenessレベルを構成できます。以下は有効なレベルですが、確認のため`man 1 ionice`を参照してください。

- `0`または`None`
- `1`または`Realtime`
- `2`または `Best-effort`（デフォルト）
- `3`または`Idle`

## 期限切れのActiveSessionルックアップキーを削除 {#remove-expired-activesession-lookup-keys}

期限切れのActiveSessionルックアップキーを削除するには:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake gitlab:cleanup:sessions:active_sessions_lookup_keys
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
bundle exec rake gitlab:cleanup:sessions:active_sessions_lookup_keys RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

## コンテナレジストリのガベージコレクション {#container-registry-garbage-collection}

コンテナレジストリは、かなりのディスク容量を使用する可能性があります。未使用のレイヤーをクリアするために、レジストリには[ガベージコレクションコマンド](../packages/container_registry.md#container-registry-garbage-collection)が含まれています。
