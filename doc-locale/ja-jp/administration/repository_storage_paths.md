---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: no
title: リポジトリのストレージ
description: GitLabがリポジトリデータを保存する方法。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、リポジトリのストレージに[リポジトリ](../user/project/repository/_index.md)を保存します。リポジトリのストレージは次のいずれかです。

- [Gitalyノード](gitaly/_index.md)を指す`gitaly_address`で設定された物理ストレージ。
- Gitalyクラスターにリポジトリを保存する[仮想ストレージ](gitaly/praefect/_index.md#virtual-storage)。

{{< alert type="warning" >}}

リポジトリのストレージは、リポジトリが保存されているディレクトリを直接指す`path`として設定できます。しかし、リポジトリを含むディレクトリへGitLabが直接アクセスする方法は非推奨となりました。物理ストレージまたは仮想ストレージを介してリポジトリにアクセスするようにGitLabを設定する必要があります。

{{< /alert >}}

詳細:

- Gitalyの設定については、[Gitalyを設定する](gitaly/configure_gitaly.md)を参照してください。
- Gitalyクラスター（Praefect）の[Configure Gitaly Cluster (Praefect)](gitaly/praefect/configure.md)（Gitalyクラスター（Praefect）の構成）を参照してください。

## ハッシュ化されたストレージ {#hashed-storage}

{{< history >}}

- GitLab 14.0で、プロジェクトパスに基づいてリポジトリパスが生成されていた従来のストレージのサポートは完全に削除されました。
- GitLab 16.3で、**Gitalyストレージ名**フィールドは**ストレージ名**フィールドに、**Gitaly相対パス**フィールドは**相対パス**フィールドに、[名称が変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128416)されました。

{{< /history >}}

ハッシュ化されたストレージは、プロジェクトのIDのハッシュに基づいて、プロジェクトをディスク上の場所に保存します。これにより、フォルダ構造が不変になり、URLからディスク構造への状態の同期が不要になります。つまり、グループ、ユーザー、またはプロジェクトの名前を変更した場合は、次のようになります。

- 必要な処理はデータベーストランザクションのみです。
- 即座に反映されます。

また、ハッシュは、リポジトリをディスク上でより均等に分散させる効果もあります。トップレベルディレクトリに含まれるフォルダの数は、トップレベルのネームスペースの総数よりも少なくなります。

ハッシュ形式は、`SHA256(project.id)`で計算された、SHA256の16進数表現に基づいています。トップレベルのフォルダは、ハッシュの最初の2文字を使用し、その下に次の2文字を使用した別のフォルダが続きます。どちらも特別な`@hashed`フォルダに保存されるため、既存のレガシーストレージプロジェクトとの共存が可能です。次に例を示します。

```ruby
# Project's repository:
"@hashed/#{hash[0..1]}/#{hash[2..3]}/#{hash}.git"

# Wiki's repository:
"@hashed/#{hash[0..1]}/#{hash[2..3]}/#{hash}.wiki.git"
```

### ハッシュ化されたストレージパスを変換する {#translate-hashed-storage-paths}

Gitリポジトリに関する問題のトラブルシューティング、フックの追加、その他のタスクでは、人間が読めるプロジェクト名とハッシュ化されたストレージパスの間で変換が必要になります。次の変換が可能です。

- [プロジェクト名からハッシュ化されたパス](#from-project-name-to-hashed-path)。
- [ハッシュ化されたパスからプロジェクト名](#from-hashed-path-to-project-name)。

#### プロジェクト名からハッシュ化されたパス {#from-project-name-to-hashed-path}

管理者は次のいずれかを使用して、プロジェクト名またはIDからプロジェクトのハッシュ化されたパスを調べることができます。

- [**管理者**エリア](admin_area.md#administering-projects)。
- Railsコンソール。

**管理者**エリアでプロジェクトのハッシュ化されたパスを調べるには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要 > プロジェクト**を選択し、プロジェクトを選択します。
1. **相対パス**フィールドを探します。値は次のようになります。

   ```plaintext
   "@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git"
   ```

Railsコンソールを使用してプロジェクトのハッシュ化されたパスを調べるには、次の手順に従います。

1. [Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)を起動します。
1. 次の例のようなコマンドを実行します（プロジェクトのIDまたは名前のいずれかを使用します）。

   ```ruby
   Project.find(16).disk_path
   Project.find_by_full_path('group/project').disk_path
   ```

#### ハッシュ化されたパスからプロジェクト名 {#from-hashed-path-to-project-name}

管理者は次のいずれかを使用して、ハッシュ化された相対パスからプロジェクト名を検索できます。

- Railsコンソール。
- `*.git`ディレクトリ内の`config`ファイル。

Railsコンソールを使用してプロジェクト名を調べるには、次の手順に従います。

1. [Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)を起動します。
1. 次の例のようなコマンドを実行します。

   ```ruby
   ProjectRepository.find_by(disk_path: '@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9').project
   ```

このコマンド内の引用符で囲まれた文字列は、GitLabサーバーで確認できるディレクトリツリーです。たとえば、デフォルトのLinuxパッケージインストールでは`/var/opt/gitlab/git-data/repositories/@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git`のようになり、このディレクトリ名の末尾から`.git`を除きます。

出力には、プロジェクトIDとプロジェクト名が含まれます。次に例を示します。

```plaintext
=> #<Project id:16 it/supportteam/ticketsystem>
```

#### ハッシュ化されたパスからプロジェクトのフルパスへの変換 {#from-hashed-path-to-full-path-of-a-project}

Railsコンソールを使用してプロジェクトのフルパスを調べるには、次の手順に従います。

1. [Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)を起動します。
1. 次の例のようなコマンドを実行します。

   ```ruby
   ProjectRepository.find_by(disk_path: '@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9').project.full_path
   ```

   このコマンド内の引用符で囲まれた文字列は、GitLabサーバー上にあるディレクトリツリーです。たとえば、デフォルトのLinuxパッケージインストールでは`/var/opt/gitlab/git-data/repositories/@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git`のようになり、このディレクトリ名の末尾から`.git`を除きます。

この出力には、プロジェクトのフルパスが含まれています。次に例を示します。

```plaintext
=> "it/supportteam/ticketsystem"
```

### ハッシュ化されたオブジェクトプール {#hashed-object-pools}

オブジェクトプールは、[公開および内部プロジェクトのフォーク](../user/project/repository/forking_workflow.md)を重複排除するために使用されるリポジトリで、元のプロジェクトのオブジェクトが含まれています。`objects/info/alternates`を使用すると、元のプロジェクトとそのフォークは、共有オブジェクトに対してこのオブジェクトプールを使用します。詳細については、GitLab開発ドキュメントのGitオブジェクト重複排除の情報を参照してください。

オブジェクトは、元のプロジェクトでハウスキーピングが実行されたときに、元のプロジェクトからオブジェクトプールに移動されます。オブジェクトプールリポジトリは、`@hashed`ではなく`@pools`というディレクトリ内に、通常のリポジトリと同様に保存されます。

```ruby
# object pool paths
"@pools/#{hash[0..1]}/#{hash[2..3]}/#{hash}.git"
```

{{< alert type="warning" >}}

`@pools`ディレクトリに保存されているオブジェクトプールリポジトリでは、`git prune`または`git gc`を実行しないでください。これらの操作を行うと、オブジェクトプールに依存している通常のリポジトリでデータが失われる可能性があります。

{{< /alert >}}

### ハッシュ化されたオブジェクトプールストレージパスを変換する {#translate-hashed-object-pool-storage-paths}

Railsコンソールを使用してプロジェクトのオブジェクトプールを調べるには、次の手順に従います。

1. [Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)を起動します。
1. 次の例のようなコマンドを実行します。

   ```ruby
   project_id = 1
   pool_repository = Project.find(project_id).pool_repository
   pool_repository = Project.find_by_full_path('group/project').pool_repository

   # Get more details about the pool repository
   pool_repository.source_project
   pool_repository.member_projects
   pool_repository.shard
   pool_repository.disk_path
   ```

### グループWikiストレージ {#group-wiki-storage}

`@hashed`ディレクトリに保存されているプロジェクトWikiとは異なり、グループWikiは`@groups`というディレクトリに保存されます。プロジェクトWikiと同様に、グループWikiはハッシュ化されたストレージのフォルダ規則に従いますが、プロジェクトIDではなくグループIDのハッシュを使用します。

次に例を示します。

```ruby
# group wiki paths
"@groups/#{hash[0..1]}/#{hash[2..3]}/#{hash}.wiki.git"
```

### Gitalyクラスター（Praefect）ストレージ {#gitaly-cluster-praefect-storage}

Gitalyクラスター（Praefect）を使用している場合、Praefectがリポジトリストレージの場所を管理します。Praefectがリポジトリに使用する内部パスは、ハッシュ化されたパスとは異なります。詳細については、[Praefectによって生成されるレプリカパス](gitaly/praefect/_index.md#praefect-generated-replica-paths)を参照してください。

### リポジトリのファイルアーカイブキャッシュ {#repository-file-archive-cache}

ユーザーは、次のいずれかを使用して、`.zip`や`.tar.gz`などの形式でリポジトリのアーカイブをダウンロードできます。

- GitLab UI。
- [リポジトリAPI](../api/repositories.md#get-file-archive)。

GitLabは、このアーカイブをGitLabサーバー上のディレクトリのキャッシュに保存します。

Sidekiqで実行されているバックグラウンドジョブが、このディレクトリから古くなったアーカイブを定期的にクリーンアップします。このため、このディレクトリにはSidekiqサービスとGitLab Workhorseサービスの両方からアクセスできる必要があります。GitLab Workhorseが使用しているディレクトリにSidekiqがアクセスできない場合、[そのディレクトリを含むディスクがいっぱいになるおそれがあります](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6005)。

SidekiqとGitLab Workhorseに共有マウントを使用させたくない場合は、代わりに、このディレクトリからファイルを削除する個別の`cron`ジョブを設定することもできます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

ファイルアーカイブキャッシュのデフォルトのディレクトリは、`/var/opt/gitlab/gitlab-rails/shared/cache/archive`です。これは、`/etc/gitlab/gitlab.rb`の`gitlab_rails['gitlab_repository_downloads_path']`設定で変更できます。

キャッシュを無効にするには、次の手順に従います。

1. Pumaを実行しているすべてのノードで、環境変数`WORKHORSE_ARCHIVE_CACHE_DISABLED`を設定します。

   ```shell
   sudo -e /etc/gitlab/gitlab.rb
   ```

   ```ruby
   gitlab_rails['env'] = { 'WORKHORSE_ARCHIVE_CACHE_DISABLED' => '1' }
   ```

1. 変更を有効にするため、更新されたノードを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

Helmチャートは、キャッシュを`/srv/gitlab/shared/cache/archive`に保存します。このディレクトリの設定は変更できません。

キャッシュを無効にするには、`--set gitlab.webservice.extraEnv.WORKHORSE_ARCHIVE_CACHE_DISABLED="1"`を使用するか、valuesファイルで次のように指定します。

```yaml
gitlab:
  webservice:
    extraEnv:
      WORKHORSE_ARCHIVE_CACHE_DISABLED: "1"
```

{{< /tab >}}

{{< /tabs >}}

### オブジェクトストレージのサポート {#object-storage-support}

次の表は、各ストレージタイプで保存可能なオブジェクトを示しています。

| 保存可能なオブジェクト  | ハッシュ化されたストレージ | S3互換 |
|:-----------------|:---------------|:--------------|
| リポジトリ       | 対応            | –             |
| 添付ファイル      | 対応            | –             |
| アバター          | 非対応             | –             |
| Pages            | 非対応             | –             |
| Dockerレジストリ  | 非対応             | –             |
| CI/CDジョブログ   | 非対応             | –             |
| CI/CDアーティファクト  | 非対応             | 対応           |
| CI/CDキャッシュ      | 非対応             | 対応           |
| LFSオブジェクト      | 類似の仕組みで対応        | 対応           |
| リポジトリプール | 対応            | –             |

S3互換のエンドポイントに保存されたファイルは、`#{namespace}/#{project_name}`というプレフィックスが付加されていない限り、[ハッシュ化されたストレージ](#hashed-storage)と同じメリットを得られます。これは、CI/CDキャッシュやLFSオブジェクトに当てはまります。

#### アバター {#avatars}

各ファイルは、データベースで割り当てられた`id`に対応するディレクトリに保存されます。ユーザーアバターの場合、ファイル名は常に`avatar.png`です。アバターが置き換えられると、`Upload`モデルが破棄され、別の`id`を持つ新しいモデルが作成されます。

#### CI/CDアーティファクト {#cicd-artifacts}

CI/CDアーティファクトはS3互換です。

#### LFSオブジェクト {#lfs-objects}

[GitLabにおけるLFSオブジェクト](../topics/git/lfs/_index.md)は、Gitの実装に従って、2文字と2階層のフォルダを使用する類似のストレージパターンで保存されます。

```ruby
"shared/lfs-objects/#{oid[0..1}/#{oid[2..3]}/#{oid[4..-1]}"

# Based on object `oid`: `8909029eb962194cfb326259411b22ae3f4a814b5be4f80651735aeef9f3229c`, path will be:
"shared/lfs-objects/89/09/029eb962194cfb326259411b22ae3f4a814b5be4f80651735aeef9f3229c"
```

LFSオブジェクトも[S3互換](lfs/_index.md#storing-lfs-objects-in-remote-object-storage)です。

## 新しいリポジトリの保存先を設定する {#configure-where-new-repositories-are-stored}

[複数のリポジトリのストレージを設定](https://docs.gitlab.com/omnibus/settings/configuration.html#store-git-data-in-an-alternative-directory)した後、新しいリポジトリの保存先を選択できます。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定 > リポジトリ**を選択します。
1. **リポジトリのストレージ**を展開します。
1. **新しいリポジトリのためのストレージノード**フィールドに値を入力します。
1. **変更を保存**を選択します。

各リポジトリのストレージパスには、0 - 100のウェイトを割り当てることができます。新しいプロジェクトを作成すると、これらのウェイトに基づいて、リポジトリが作成されるストレージの場所が決まります。

あるリポジトリのストレージパスのウェイトが他のリポジトリのストレージパスに比べて高いほど、そのストレージが選択される頻度も高くなります（`(storage weight) / (sum of all weights) * 100 = chance %`）。

デフォルトでは、リポジトリのウェイトがまだ設定されていない場合は、以下のとおりです。

- `default`のウェイトは`100`です。
- その他すべてのストレージのウェイトは`0`です。

{{< alert type="note" >}}

すべてのストレージのウェイトが`0`の場合（たとえば、`default`が存在しない場合）、GitLabは設定に関係なく、また`default`が存在するかにかかわらず、新しいリポジトリを`default`に作成しようとします。詳細については、[トラッキングイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/36175)を参照してください。

{{< /alert >}}

## リポジトリを移動する {#move-repositories}

リポジトリを別のリポジトリストレージ（たとえば、`default`から`storage2`）に移行するには、[Gitaly Cluster（Praefect）への移行](gitaly/praefect/_index.md#migrate-to-gitaly-cluster-praefect)と同じプロセスを使用します。
