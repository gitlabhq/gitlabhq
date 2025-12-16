---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アップロード移行Rakeタスク
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

異なるストレージタイプ間でアップロードを移行するためのRakeタスクがあります。

- [`gitlab:uploads:migrate:all`](#all-in-one-rake-task)ですべてのアップロードを移行するか
- 特定のアップロードタイプのみを移行するには、[`gitlab:uploads:migrate`](#individual-rake-tasks)を使用します。

## オブジェクトストレージに移行する {#migrate-to-object-storage}

GitLabのアップロード用に[オブジェクトストレージを設定](../../uploads.md#using-object-storage)した後、このタスクを使用して、既存のアップロードをローカルストレージからリモートストレージに移行します。

この処理はバックグラウンドワーカーで実行され、**no downtime**（ダウンタイムは不要）です。

[GitLabでのオブジェクトストレージの使用](../../object_storage.md)について、こちらをご覧ください。

### オールインワンRakeタスク {#all-in-one-rake-task}

GitLabには、すべてのアップロードファイル（アバター、ロゴ、添付ファイル、faviconなど）を1つのステップでオブジェクトストレージに移行するラッパーRakeタスクが用意されています。このラッパータスクは、これらのカテゴリのそれぞれに該当するファイルを1つずつ移行するために、個別のRakeタスクを実行します。

これらの[個別のRakeタスク](#individual-rake-tasks)については、次のセクションで説明します。

すべてのアップロードをローカルストレージからオブジェクトストレージに移行するには、以下を実行します:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
gitlab-rake "gitlab:uploads:migrate:all"
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:migrate:all
```

{{< /tab >}}

{{< /tabs >}}

[PostgreSQLコンソール](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-bundled-postgresql-database)を使用して、進行状況を追跡し、すべてのアップロードが正常に移行したことを確認できます:

- Linuxパッケージインストールの場合: `sudo gitlab-rails dbconsole --database main`。
- 自己コンパイルによるインストールの場合: `sudo -u git -H psql -d gitlabhq_production`。

以下に示す`objectstg`（`store=2`の場合）に、すべてのアーティファクトの数が含まれていることを確認します:

```shell
gitlabhq_production=# SELECT count(*) AS total, sum(case when store = '1' then 1 else 0 end) AS filesystem, sum(case when store = '2' then 1 else 0 end) AS objectstg FROM uploads;

total | filesystem | objectstg
------+------------+-----------
   2409 |          0 |      2409
```

ディスク上の`uploads`フォルダーにファイルがないことを確認します:

```shell
sudo find /var/opt/gitlab/gitlab-rails/uploads -type f | grep -v tmp | wc -l
```

### 個別のRakeタスク {#individual-rake-tasks}

すでに[オールインワンRakeタスク](#all-in-one-rake-task)を実行している場合は、これらの個別のタスクを実行する必要はありません。

このRakeタスクは、移行するアップロードを検索するために、3つのパラメータを使用します:

| パラメータ        | 型          | 説明                                            |
|:-----------------|:--------------|:-------------------------------------------------------|
| `uploader_class` | 文字列        | 移行元のアップローダーのタイプ。                  |
| `model_class`    | 文字列        | 移行元のモデルのタイプ。                     |
| `mount_point`    | 文字列/シンボル | アップローダーがマウントされているモデルの列の名前。 |

{{< alert type="note" >}}

これらのパラメータは、主にGitLabの構造の内部的なものなので、代わりに以下のタスクリストを参照してください。これらの個別のタスクを実行した後、一覧表示されているタイプに含まれていないアップロードを移行するために、[オールインワンRakeタスク](#all-in-one-rake-task)を実行することをお勧めします。

{{< /alert >}}

このタスクは、デフォルトのバッチサイズをオーバーライドするために使用できる環境変数も受け入れます:

| 変数 | 型    | 説明                                       |
|:---------|:--------|:--------------------------------------------------|
| `BATCH`  | 整数 | バッチのサイズを指定します。デフォルトは200です。 |

以下に、個々のタイプのアップロードに対して`gitlab:uploads:migrate`を実行する方法を示します。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
# gitlab-rake gitlab:uploads:migrate[uploader_class, model_class, mount_point]

# Avatars
gitlab-rake "gitlab:uploads:migrate[AvatarUploader, Project, :avatar]"
gitlab-rake "gitlab:uploads:migrate[AvatarUploader, Group, :avatar]"
gitlab-rake "gitlab:uploads:migrate[AvatarUploader, User, :avatar]"

# Attachments
gitlab-rake "gitlab:uploads:migrate[AttachmentUploader, Appearance, :logo]"
gitlab-rake "gitlab:uploads:migrate[AttachmentUploader, Appearance, :header_logo]"

# Favicon
gitlab-rake "gitlab:uploads:migrate[FaviconUploader, Appearance, :favicon]"

# Markdown
gitlab-rake "gitlab:uploads:migrate[FileUploader, Project]"
gitlab-rake "gitlab:uploads:migrate[PersonalFileUploader, Snippet]"
gitlab-rake "gitlab:uploads:migrate[NamespaceFileUploader, Snippet]"
gitlab-rake "gitlab:uploads:migrate[FileUploader, MergeRequest]"

# Design Management design thumbnails
gitlab-rake "gitlab:uploads:migrate[DesignManagement::DesignV432x230Uploader, DesignManagement::Action, :image_v432x230]"
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

すべてのタスクに`RAILS_ENV=production`を使用します。

```shell
# sudo -u git -H bundle exec rake gitlab:uploads:migrate

# Avatars
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AvatarUploader, Project, :avatar]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AvatarUploader, Group, :avatar]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AvatarUploader, User, :avatar]"

# Attachments
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AttachmentUploader, Appearance, :logo]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AttachmentUploader, Appearance, :header_logo]"

# Favicon
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[FaviconUploader, Appearance, :favicon]"

# Markdown
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[FileUploader, Project]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[PersonalFileUploader, Snippet]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[NamespaceFileUploader, Snippet]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[FileUploader, MergeRequest]"

# Design Management design thumbnails
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[DesignManagement::DesignV432x230Uploader, DesignManagement::Action]"
```

{{< /tab >}}

{{< /tabs >}}

## ローカルストレージへの移行 {#migrate-to-local-storage}

何らかの理由で[オブジェクトストレージ](../../object_storage.md)を無効にする必要がある場合は、まず、オブジェクトストレージからデータを移行して、ローカルストレージに戻す必要があります。

{{< alert type="warning" >}}

**Extended downtime is required**（長時間のダウンタイムが必要）なため、移行中に新しいファイルがオブジェクトストレージに作成されることはありません。設定変更のためにごくわずかなダウンタイムで、オブジェクトストレージからローカルファイルへの移行を許可する設定は、[このイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/30979)で追跡されます。

**Additionally,**（さらに）、Cloud Native GitLabでは、データが一時的であり、すべてのGitLab Railsアプリケーションコンテナと共有されないため、データをローカルストレージに移行するのは一般に安全ではありません。

{{< /alert >}}

### オールインワンRakeタスク {#all-in-one-rake-task-1}

GitLabには、すべてのアップロードファイル（アバター、ロゴ、添付ファイル、faviconなど）を1つのステップでローカルストレージに移行するラッパーRakeタスクが用意されています。このラッパータスクは、これらのカテゴリのそれぞれに該当するファイルを1つずつ移行するために、個別のRakeタスクを実行します。

これらのRakeタスクの詳細については、[個別のRakeタスク](#individual-rake-tasks)を参照してください。この場合のタスク名は`gitlab:uploads:migrate_to_local`であることに注意してください。

オブジェクトストレージからローカルストレージにアップロードを移行するには:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
gitlab-rake "gitlab:uploads:migrate_to_local:all"
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:migrate_to_local:all
```

{{< /tab >}}

{{< /tabs >}}

Rakeタスクの実行後、[オブジェクトストレージを設定する](../../uploads.md#using-object-storage)手順で説明されている変更を元に戻すことで、オブジェクトストレージを無効にできます。
