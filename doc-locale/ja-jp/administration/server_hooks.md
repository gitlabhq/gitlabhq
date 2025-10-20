---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Gitサーバーフック
description: Gitサーバーフックを設定します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.6で、サーバーフックからGitサーバーフックに[名称が変更](https://gitlab.com/gitlab-org/gitlab/-/issues/372991)されました。

{{< /history >}}

Gitサーバーフック（[システムフック](system_hooks.md)や[ファイルフック](file_hooks.md)と混同しないでください）は、GitLabサーバーでカスタムロジックを実行します。これにより、次のようなGit関連のタスクを実行できます。

- 特定のコミットポリシーを適用する。
- リポジトリの状態に基づいてタスクを実行する。

Gitサーバーフックは、`pre-receive`、`post-receive`、`update`の[Gitサーバーサイドフック](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks#_server_side_hooks)を使用します。

GitLab管理者は、`gitaly`コマンドを使用してサーバーフックを設定します。このコマンドには、次のような機能もあります。

- Gitalyサーバーを起動する。
- いくつかのサブコマンドを提供する。
- Gitaly gRPC APIに接続する。

`gitaly`コマンドへのアクセス権がない場合は、サーバーフックの代替手段として以下を使用できます。

- [Webhook](../user/project/integrations/webhooks.md)。
- [GitLab CI/CD](../ci/_index.md)。
- [プッシュルール](../user/project/repository/push_rules.md)（ユーザーが設定可能なGitフックのインターフェース）。

[Geo](geo/_index.md)は、サーバーフックをセカンダリノードにレプリケートしません。

## リポジトリのサーバーフックを設定する {#set-server-hooks-for-a-repository}

{{< history >}}

- GitLab 15.11で[導入](https://gitlab.com/gitlab-org/gitaly/-/issues/4629)された`hooks set`コマンドは、ファイルシステムへの直接アクセスに代わるものです。既存のGitフックは、`hooks set`コマンドのために移行する必要はありません。

{{< /history >}}

{{< tabs >}}

{{< tab title="GitLab 15.11以降" >}}

前提要件:

- [ストレージ名](gitaly/configure_gitaly.md#gitlab-requires-a-default-repository-storage)、Gitaly設定ファイルのパス（Linuxパッケージインスタンスではデフォルトは`/var/opt/gitlab/gitaly/config.toml`）、[リポジトリの相対パス](repository_storage_paths.md#from-project-name-to-hashed-path)。
- フックに必要な言語ランタイムとユーティリティが、Gitalyを実行する各サーバーにインストールされている必要があります。

リポジトリのサーバーフックを設定するには、次の手順に従います。

1. カスタムフックを含むtarballを作成します。
   1. サーバーフックが期待どおりに動作するようにコードを記述します。Gitサーバーフックは、任意のプログラミング言語で作成できます。言語の種類に応じて、スクリプトの先頭に[シバン](https://en.wikipedia.org/wiki/Shebang_(Unix))を記述してください。たとえば、Rubyでスクリプトを記述する場合、シバンはおそらく`#!/usr/bin/env ruby`となります。

      - 単一のサーバーフックを作成するには、フックタイプに対応する名前のファイルを作成します。たとえば、`pre-receive`サーバーフックの場合、ファイル名は拡張子なしで`pre-receive`にします。
      - 複数のサーバーフックを作成するには、フックタイプに対応する名前のディレクトリを作成します。たとえば、`pre-receive`サーバーフックの場合、ディレクトリ名は`pre-receive.d`にします。そのディレクトリに、フックのファイルを配置します。

   1. サーバーフックファイルが実行可能であり、バックアップファイルのパターン（`*~`）に一致していないことを確認します。サーバーフックは、tarballのルートにある`custom_hooks`ディレクトリに配置されている必要があります。
   1. tarコマンドを使用して、カスタムフックアーカイブを作成します。例: `tar -cf custom_hooks.tar custom_hooks`。
1. 必要なオプションを指定して`hooks set`サブコマンドを実行し、リポジトリのGitフックを設定します。例: `cat custom_hooks.tar | sudo -u git -- /opt/gitlab/embedded/bin/gitaly hooks set --storage <storage> --repository <relative path> --config <config path>`。

   - ノードに接続するには、そのノードの有効なGitaly設定のパスを`--config`フラグで指定する必要があります。
   - カスタムフックのtarballは、`stdin`を通じて渡す必要があります。例: `cat custom_hooks.tar | sudo -u git -- /opt/gitlab/embedded/bin/gitaly hooks set --storage <storage> --repository <relative path> --config <config path>`。
1. Gitalyクラスター（Praefect）を使用している場合は、すべてのGitalyノードで`hooks set`サブコマンドを実行する必要があります。詳細については、[Server hooks on a Gitaly Cluster (Praefect)](#server-hooks-on-a-gitaly-cluster-praefect)を参照してください。

サーバーフックコードが正しく実装されていれば、次回Gitフックがトリガーされたときにそのコードが実行されるはずです。

{{< /tab >}}

{{< tab title="GitLab 15.10以前" >}}

リポジトリのサーバーフックを作成するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要 > プロジェクト**に移動し、サーバーフックを追加するプロジェクトを選択します。
1. 表示されたページで、**相対パス**の値を確認します。サーバーフックは、このパスに配置する必要があります。
   - [ハッシュ化されたストレージ](repository_storage_paths.md#hashed-storage)を使用している場合、相対パスの解釈については、[ハッシュ化されたストレージパスを変換する](repository_storage_paths.md#translate-hashed-storage-paths)を参照してください。
   - [ハッシュ化されたストレージ](repository_storage_paths.md#hashed-storage)を使用していない場合は、以下のとおりです。
     - Linuxパッケージインストールの場合、パスは通常`/var/opt/gitlab/git-data/repositories/<group>/<project>.git`です。
     - 自己コンパイルによるインストールの場合、パスは通常`/home/git/repositories/<group>/<project>.git`です。
1. ファイルシステムで、正しい場所に`custom_hooks`という新しいディレクトリを作成します。
1. 新しい`custom_hooks`ディレクトリで、以下を実行します。
   - 単一のサーバーフックを作成するには、フックタイプに対応する名前のファイルを作成します。たとえば、`pre-receive`サーバーフックの場合、ファイル名は拡張子なしで`pre-receive`にします。
   - 複数のサーバーフックを作成するには、フックタイプに対応する名前のディレクトリを作成します。たとえば、`pre-receive`サーバーフックの場合、ディレクトリ名は`pre-receive.d`にします。そのディレクトリに、フックのファイルを配置します。
1. サーバーフックのファイルを実行可能にし、Gitユーザーが所有していることを確認します。
1. サーバーフックが期待どおりに動作するようにコードを記述します。Gitサーバーフックは、任意のプログラミング言語で作成できます。言語の種類に応じて、スクリプトの先頭に[シバン](https://en.wikipedia.org/wiki/Shebang_(Unix))を記述してください。たとえば、Rubyでスクリプトを記述する場合、シバンはおそらく`#!/usr/bin/env ruby`となります。
1. フックファイルがバックアップファイルのパターン（`*~`）に一致していないことを確認します。
1. Gitalyクラスター（Praefect）を使用している場合は、すべてのGitalyノードでこのプロセスを繰り返す必要があります。詳細については、[Server hooks on a Gitaly Cluster (Praefect)](#server-hooks-on-a-gitaly-cluster-praefect)を参照してください。

サーバーフックコードが正しく実装されていれば、次回Gitフックがトリガーされたときにそのコードが実行されるはずです。

{{< /tab >}}

{{< /tabs >}}

### Gitaly Clusterのサーバーフック（Praefect） {#server-hooks-on-a-gitaly-cluster-praefect}

[Gitaly Cluster](gitaly/praefect/_index.md)を使用している場合、単一のリポジトリがPraefect内の複数のGitalyストレージにレプリケートされることがあります。そのため、フックスクリプトは、リポジトリのレプリカが存在するすべてのGitalyノードにコピーする必要があります。これを実現するには、該当バージョンに対応したカスタムリポジトリフックの設定手順に従い、各ストレージに対して同様の作業を繰り返します。

スクリプトのコピー先は、リポジトリの保存場所によって異なります。GitLab 15.3以降では、新しいリポジトリは、ハッシュストレージパスではなく、[Praefectによって生成されたレプリカパス](gitaly/praefect/_index.md#praefect-generated-replica-paths)を使用して作成されます。レプリカパスを特定するには、`-relative-path`を使用してGitLabのハッシュ化されたストレージパスとして想定される値を指定し、[Praefectのリポジトリメタデータをクエリ](gitaly/praefect/troubleshooting.md#view-repository-metadata)します。

## すべてのリポジトリに適用されるグローバルサーバーフックを作成する {#create-global-server-hooks-for-all-repositories}

すべてのリポジトリに適用されるGitフックを作成するには、グローバルサーバーフックを設定します。グローバルサーバーフックは、以下にも適用されます。

- [プロジェクトおよびグループのWiki](../user/project/wiki/_index.md)リポジトリ。これらのストレージディレクトリ名は、`<id>.wiki.git`という形式になります。
- プロジェクトの[設計管理](../user/project/issues/design_management.md)リポジトリ。これらのストレージディレクトリ名は、`<id>.design.git`という形式になります。

### サーバーフックのディレクトリを選択する {#choose-a-server-hook-directory}

グローバルサーバーフックを作成する前に、使用するディレクトリを選択する必要があります。

Linuxパッケージインストールの場合、ディレクトリは`gitaly['configuration'][:hooks][:custom_hooks_dir]`の`gitlab.rb`で設定します。次のいずれかの方法があります。

- コメントアウトを解除して、`/var/opt/gitlab/gitaly/custom_hooks`ディレクトリのデフォルトの提案を使用する。
- 独自の設定を追加する。

自己コンパイルによるインストールの場合、以下のとおりです。

- ディレクトリは`[hooks]`セクションの`gitaly/config.toml`で設定します。ただし、`gitaly/config.toml`の値が空白または存在しない場合、GitLabは`gitlab-shell/config.yml`の`custom_hooks_dir`の値を優先します。
- デフォルトのディレクトリは`/home/git/gitlab-shell/hooks`です。

### グローバルサーバーフックを作成する {#create-the-global-server-hook}

すべてのリポジトリに適用されるグローバルサーバーフックを作成するには、次の手順に従います。

1. GitLabサーバーで、設定済みのグローバルサーバーフック用ディレクトリに移動します。
1. 設定済みのグローバルサーバーフック用ディレクトリで、フックタイプに対応する名前のディレクトリを作成します。たとえば、`pre-receive`サーバーフックの場合、ディレクトリ名は`pre-receive.d`にします。
1. この新しいディレクトリ内に、サーバーフックを追加します。Gitサーバーフックは、任意のプログラミング言語で作成できます。言語の種類に応じて、スクリプトの先頭に[シバン](https://en.wikipedia.org/wiki/Shebang_(Unix))を記述してください。たとえば、Rubyでスクリプトを記述する場合、シバンはおそらく`#!/usr/bin/env ruby`となります。
1. フックファイルを実行可能にし、Gitユーザーが所有していること、およびバックアップファイルのパターン（`*~`）に一致していないことを確認します。

サーバーフックコードが正しく実装されていれば、次回Gitフックがトリガーされたときにそのコードが実行されるはずです。フックは、フックタイプ別サブディレクトリ内で、ファイル名のアルファベット順に実行されます。

## リポジトリのサーバーフックを削除する {#remove-server-hooks-for-a-repository}

{{< history >}}

- GitLab 15.11で[導入](https://gitlab.com/gitlab-org/gitaly/-/issues/4629)された`hooks set`コマンドは、ファイルシステムへの直接アクセスに代わるものです。

{{< /history >}}

{{< tabs >}}

{{< tab title="GitLab 15.11以降" >}}

前提要件:

- リポジトリの[ストレージ名と相対パス](repository_storage_paths.md#from-project-name-to-hashed-path)。

サーバーフックを削除するには、空のtarballを`hook set`に渡して、リポジトリにフックを含めないように指示します。次に例を示します。

```shell
cat empty_hooks.tar | sudo -u git -- /opt/gitlab/embedded/bin/gitaly hooks set --storage <storage> --repository <relative path> --config <config path>
```

{{< /tab >}}

{{< tab title="GitLab 15.10以前" >}}

サーバーフックを削除するには、次の手順に従います。

1. ディスク上のリポジトリの場所に移動します。
1. `custom_hooks`ディレクトリ内のサーバーフックを削除します。

{{< /tab >}}

{{< /tabs >}}

## チェーンされたサーバーフック {#chained-server-hooks}

GitLabではサーバーフックをチェーンで実行できます。GitLabは、次の順序でサーバーフックを検索し、実行します。

- GitLabに組み込まれているサーバーフック。これらのサーバーフックをユーザーがカスタマイズすることはできません。
- `<project>.git/custom_hooks/<hook_name>`: プロジェクト単位のフック。この場所は下位互換性のために保持されています。
- `<project>.git/custom_hooks/<hook_name>.d/*`: プロジェクト単位のフックの場所。
- `<custom_hooks_dir>/<hook_name>.d/*`: エディタバックアップファイルを除く、すべての実行可能なグローバルフックファイルの場所。

サーバーフックディレクトリ内で、フックは次のように動作します。

- ファイル名のアルファベット順に実行されます。
- ゼロ以外の値でフックが終了すると、実行を停止します。

## サーバーフックで使用可能な環境変数 {#environment-variables-available-to-server-hooks}

任意の環境変数をサーバーフックに渡すことはできますが、サポートされている環境変数のみを使用する必要があります。

次のGitLab環境変数は、すべてのサーバーフックでサポートされています。

| 環境変数 | 説明                                                                                                                                                |
|:---------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| `GL_ID`              | プッシュを開始したユーザーまたはSSHキーのGitLab識別子。例: `user-2234`、`key-4`。                                                         |
| `GL_PROJECT_PATH`    | GitLabプロジェクトのパス。                                                                                                               |
| `GL_PROTOCOL`        | この変更に使用するプロトコル。次のいずれかになります。`http`（HTTPを使用したGit `push`）、`ssh`（SSHを使用したGit `push`）、`web`（その他すべての操作）。 |
| `GL_REPOSITORY`      | `project-<id>`。`id`はプロジェクトのIDです。                                                                                                        |
| `GL_USERNAME`        | プッシュを開始したユーザーのGitLabのユーザー名。                                                                                                       |

次のGit環境変数は、`pre-receive`および`post-receive`サーバーフックでサポートされています。

| 環境変数               | 説明                                                                                                                                                            |
|:-----------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `GIT_ALTERNATE_OBJECT_DIRECTORIES` | 検疫環境における代替オブジェクトディレクトリ。[Gitの`receive-pack`のドキュメント](https://git-scm.com/docs/git-receive-pack#_quarantine_environment)を参照してください。 |
| `GIT_OBJECT_DIRECTORY`             | 検疫環境におけるGitLabプロジェクトのパス。[Gitの`receive-pack`のドキュメント](https://git-scm.com/docs/git-receive-pack#_quarantine_environment)を参照してください。          |
| `GIT_PUSH_OPTION_COUNT`            | [プッシュオプション](../topics/git/commit.md#push-options)の数。Gitの`pre-receive`のドキュメントを参照してください。                                                          |
| `GIT_PUSH_OPTION_<i>`              | [プッシュオプション](../topics/git/commit.md#push-options)の値。ここで、`i`は`0`から`GIT_PUSH_OPTION_COUNT - 1`までの値です。[Gitの`pre-receive`のドキュメント](https://git-scm.com/docs/githooks#pre-receive)を参照してください。      |

## カスタムエラーメッセージ {#custom-error-messages}

コミットが拒否された場合や、Gitフックの実行中にエラーが発生した場合に、GitLab UIにカスタムエラーメッセージを表示することができます。カスタムエラーメッセージを表示するには、次のようなスクリプトを使用します。

- カスタムエラーメッセージをスクリプトの`stdout`または`stderr`に送信する。
- 各メッセージの先頭に`GL-HOOK-ERR:`を付加する（プレフィックスの前に他の文字を含めない）。

次に例を示します。

```shell
#!/bin/sh
echo "GL-HOOK-ERR: My custom error message.";
exit 1
```
