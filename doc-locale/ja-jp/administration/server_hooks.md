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

GitLabサーバー上でサーバーフックはカスタムロジックを実行します。これにより、次のようなGit関連のタスクを実行できます:

- 特定のコミットポリシーを適用する。
- リポジトリの状態に基づいてタスクを実行する。

Gitサーバーフックは、`pre-receive`、`post-receive`、`update`のGitサーバー側のフックを使用します。

GitLab管理者は、`gitaly`コマンドを使用してサーバーフックを設定します。このコマンドには、次のような機能もあります:

- Gitalyサーバーを起動する。
- いくつかのサブコマンドを提供する。
- Gitaly gRPC APIに接続する。

`gitaly`コマンドへのアクセス権がない場合は、サーバーフックの代替手段として以下を使用できます:

- [Webhook](../user/project/integrations/webhooks.md)。
- [GitLab CI/CD](../ci/_index.md)。
- [プッシュルール](../user/project/repository/push_rules.md)（ユーザーが設定可能なGitフックのインターフェース）。

GitLab Helmチャートのインスタンスについては、[Gitalyチャートのグローバルサーバーフック](https://docs.gitlab.com/charts/charts/gitlab/gitaly/#global-server-hooks)に関する情報を参照してください。

{{< alert type="note" >}}

[Geo](geo/_index.md)は、サーバーフックをセカンダリノードにレプリケートしません。

{{< /alert >}}

## 前提要件 {#prerequisites}

- [ストレージ名](gitaly/configure_gitaly.md#gitlab-requires-a-default-repository-storage)、Gitaly設定ファイルのパス（Linuxパッケージインスタンスではデフォルトは`/var/opt/gitlab/gitaly/config.toml`）、[リポジトリの相対パス](repository_storage_paths.md#from-project-name-to-hashed-path)。
- フックに必要な言語ランタイムとユーティリティが、Gitalyを実行する各サーバーにインストールされている必要があります。

## リポジトリのサーバーフックを設定する {#set-server-hooks-for-a-repository}

リポジトリのサーバーフックを設定するには、次の手順に従います:

1. カスタムフックを含むtarballを作成します:
   1. サーバーフックが期待どおりに動作するようにコードを記述します。Gitサーバーフックは、任意のプログラミング言語で作成できます。言語の種類に応じて、スクリプトの先頭にシバンを記述してください。たとえば、Rubyでスクリプトを記述する場合、シバンはおそらく`#!/usr/bin/env ruby`となります。

      - 単一のサーバーフックを作成するには、フックタイプに対応する名前のファイルを作成します。たとえば、`pre-receive`サーバーフックの場合、ファイル名は拡張子なしで`pre-receive`にします。
      - 複数のサーバーフックを作成するには、フックタイプに対応する名前のディレクトリを作成します。たとえば、`pre-receive`サーバーフックの場合、ディレクトリ名は`pre-receive.d`にします。そのディレクトリに、フックのファイルを配置します。

   1. サーバーフックファイルが実行可能であり、バックアップファイルのパターン（`*~`）に一致していないことを確認します。サーバーフックは、tarballのルートにある`custom_hooks`ディレクトリに配置されている必要があります。
   1. tarコマンドを使用して、カスタムフックアーカイブを作成します。例: `tar -cf custom_hooks.tar custom_hooks`。
1. 必要なオプションを指定して`hooks set`サブコマンドを実行し、リポジトリのGitフックを設定します。次に例を示します:

   ```shell
   cat custom_hooks.tar | sudo -u git -- /opt/gitlab/embedded/bin/gitaly hooks set --storage <storage> --repository <relative path> --config <config path>
   ```

   - ノードに接続するには、そのノードの有効なGitaly設定のパスを`--config`フラグで指定する必要があります。
   - カスタムフックのtarballは、`stdin`を通じて渡す必要があります。次に例を示します:

     ```shell
     cat custom_hooks.tar | sudo -u git -- /opt/gitlab/embedded/bin/gitaly hooks set --storage <storage> --repository <relative path> --config <config path>
     ```

1. Gitaly Cluster (Praefect)を使用している場合は、すべてのGitalyノードで`hooks set`サブコマンドを実行する必要があります。

サーバーフックコードが正しく実装されていれば、次回Gitフックがトリガーされたときにそのコードが実行されるはずです。

### Gitaly Cluster (Praefect)のサーバーフック {#server-hooks-on-a-gitaly-cluster-praefect}

Gitaly Clusterを使用している場合、単一のリポジトリがPraefect内の複数のGitalyストレージにレプリケートされることがあります。そのため、フックスクリプトは、リポジトリのレプリカが存在するすべてのGitalyノードにコピーする必要があります。これを実現するには、該当バージョンに対応したカスタムリポジトリフックの設定手順に従い、各ストレージに対して同様の作業を繰り返します。

スクリプトのコピー先は、リポジトリの保存場所によって異なります。新しいリポジトリは、ハッシュストレージパスではなく、Praefectによって生成されたレプリカパスを使用して作成されます。レプリカパスを特定するには、`-relative-path`オプションを使用して、予期されるGitLabのハッシュストレージパスを指定して、[Praefectリポジトリメタデータをクエリします](gitaly/praefect/troubleshooting.md#view-repository-metadata)。

## すべてのリポジトリに適用されるグローバルサーバーフックを作成する {#create-global-server-hooks-for-all-repositories}

すべてのリポジトリに適用されるGitフックを作成するには、グローバルサーバーフックを設定します。グローバルサーバーフックは、以下にも適用されます:

- プロジェクトおよびグループウィキのWikiリポジトリ。これらのストレージディレクトリ名は、`<id>.wiki.git`という形式になります。
- プロジェクトの設計管理リポジトリ。これらのストレージディレクトリ名は、`<id>.design.git`という形式になります。

### サーバーフックのディレクトリを選択する {#choose-a-server-hook-directory}

グローバルサーバーフックを作成する前に、使用するディレクトリを選択する必要があります。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

このディレクトリは、`gitaly['configuration'][:hooks][:custom_hooks_dir]`の`gitlab.rb`で設定します。次のいずれかの方法があります:

- コメントアウトを解除して、`/var/opt/gitlab/gitaly/custom_hooks`ディレクトリのデフォルトの提案を使用する。
- 独自の設定を追加する。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

- ディレクトリは`[hooks]`セクションの`gitaly/config.toml`で設定します。ただし、`gitaly/config.toml`の値が空白または存在しない場合、GitLabは`gitlab-shell/config.yml`の`custom_hooks_dir`の値を優先します。
- デフォルトのディレクトリは`/home/git/gitlab-shell/hooks`です。

{{< /tab >}}

{{< /tabs >}}

### グローバルサーバーフックを作成する {#create-the-global-server-hook}

すべてのリポジトリに適用されるグローバルサーバーフックを作成するには、次の手順に従います:

1. GitLabサーバーで、設定済みのグローバルサーバーフック用ディレクトリに移動します。
1. 設定済みのグローバルサーバーフック用ディレクトリで、フックタイプに対応する名前のディレクトリを作成します。たとえば、`pre-receive`サーバーフックの場合、ディレクトリ名は`pre-receive.d`にします。
1. この新しいディレクトリ内に、サーバーフックを追加します。Gitサーバーフックは、任意のプログラミング言語で作成できます。言語の種類に応じて、スクリプトの先頭にシバン (`#!`) を記述してください。たとえば、Rubyでスクリプトを記述する場合、シバンはおそらく`#!/usr/bin/env ruby`となります。
1. フックファイルを実行可能にし、Gitユーザーが所有していること、およびバックアップファイルのパターン（`*~`）に一致していないことを確認します。

サーバーフックコードが正しく実装されていれば、次回Gitフックがトリガーされたときにそのコードが実行されるはずです。フックは、フックタイプ別サブディレクトリ内で、ファイル名のアルファベット順に実行されます。

## リポジトリのサーバーフックを削除する {#remove-server-hooks-for-a-repository}

サーバーフックを削除するには、空のtarballを`hook set`に渡して、リポジトリにフックを含めないように指示します。次に例を示します:

```shell
cat empty_hooks.tar | sudo -u git -- /opt/gitlab/embedded/bin/gitaly hooks set --storage <storage> --repository <relative path> --config <config path>
```

## チェーンされたサーバーフック {#chained-server-hooks}

GitLabではサーバーフックをチェーンで実行できます。GitLabは、次の順序でサーバーフックを検索し、実行します:

- GitLabに組み込まれているサーバーフック。これらのサーバーフックをユーザーがカスタマイズすることはできません。
- `<project>.git/custom_hooks/<hook_name>`: プロジェクト単位のフック。この場所は下位互換性のために保持されています。
- `<project>.git/custom_hooks/<hook_name>.d/*`: プロジェクト単位のフックの場所。
- `<custom_hooks_dir>/<hook_name>.d/*`: エディタバックアップファイルを除く、すべての実行可能なグローバルフックファイルの場所。

サーバーフックディレクトリ内で、フックは次のように動作します:

- ファイル名のアルファベット順に実行されます。
- ゼロ以外の値でフックが終了すると、実行を停止します。

## サーバーフックで使用可能な環境変数 {#environment-variables-available-to-server-hooks}

任意の環境変数をサーバーフックに渡すことはできますが、サポートされている環境変数のみを使用する必要があります。

次のGitLab環境変数は、すべてのサーバーフックでサポートされています:

| 環境変数 | 説明 |
|:---------------------|:------------|
| `GL_ID`              | プッシュを開始したユーザーまたはSSHキーのGitLab識別子。例えば、`user-2234`や`key-4`です。 |
| `GL_PROJECT_PATH`    | GitLabプロジェクトのパス。 |
| `GL_PROTOCOL`        | この変更に使用するプロトコル。次のいずれかになります: `http`（HTTPを使用したGit `push`）、`ssh`（SSHを使用したGit `push`）、`web`（その他すべての操作）。 |
| `GL_REPOSITORY`      | `project-`のプレフィックスが付いたGitLabプロジェクトID。例：`project-1234` |
| `GL_USERNAME`        | プッシュを開始したユーザーのGitLabのユーザー名。 |

次のGit環境変数は、`pre-receive`および`post-receive`サーバーフックでサポートされています:

| 環境変数               | 説明 |
|:-----------------------------------|:------------|
| `GIT_ALTERNATE_OBJECT_DIRECTORIES` | [検疫環境](https://git-scm.com/docs/git-receive-pack#_quarantine_environment)における代替オブジェクトディレクトリ。 |
| `GIT_OBJECT_DIRECTORY`             | 検疫環境におけるGitLabプロジェクトのパス。 |
| `GIT_PUSH_OPTION_COUNT`            | [プッシュオプション](../topics/git/commit.md#push-options)の数。 |
| `GIT_PUSH_OPTION_<i>`              | 特定のプッシュオプションの値。`<i>`は、`GIT_PUSH_OPTION_COUNT`で定義された値よりも1つ少ない`0`からになります。 |

## カスタムエラーメッセージ {#custom-error-messages}

サーバーフックがプッシュを拒否した場合、プッシュが拒否された理由と問題の修正方法をユーザーが理解できるように、明確なエラーメッセージを提供します。カスタムエラーメッセージは、フックがプッシュを拒否すると、GitLab UIおよびユーザーのターミナルに表示されます。

カスタムエラーメッセージがない場合、ユーザーには`(pre-receive hook declined)`のような一般的なメッセージのみが表示されます。明確なエラーメッセージは、ユーザーに役立ちます:

- プッシュが拒否された理由を理解する。
- 管理者に連絡せずに問題を修正する。
- サポートリクエストを削減する。

カスタムエラーメッセージを表示するには、次のようなスクリプトを使用します:

- カスタムエラーメッセージをスクリプトの`stdout`または`stderr`に送信する。
- 各メッセージの先頭に`GL-HOOK-ERR:`を付加する（プレフィックスの前に他の文字を含めない）。

次に例を示します:

```shell
# Bad: Generic message
echo "GL-HOOK-ERR: Commit rejected.";

# Good: Specific message with action
echo "GL-HOOK-ERR: Commit rejected: Commit message must include an issue reference (for example, #1234).";
```

## 関連トピック {#related-topics}

- [システムフック](system_hooks.md)
- [ファイルフック](file_hooks.md)
- [Praefectによって生成されたレプリカパス](gitaly/praefect/_index.md#praefect-generated-replica-paths)

## トラブルシューティング {#troubleshooting}

Gitサーバーフックを使用する際に、次の問題が発生することがあります。

### エラー: `pre-receive hook declined` {#error-pre-receive-hook-declined}

ユーザーがGitLabリポジトリにプッシュすると、`(pre-receive hook declined)`を含むエラーメッセージが表示されることがあります。次に例を示します:

```plaintext
! [remote rejected] main (pre-receive hook declined)
error: failed to push some refs to 'https://gitlab.example.com/group/project'
```

このエラーは、事前受信フックがプッシュを拒否したことを示します。事前受信フックは、参照がリポジトリ内で更新される前に実行されます。Gitには、プッシュを拒否できる3つのサーバーサイドフックが用意されています:

- `pre-receive`: すべての参照が更新される前に実行されます。プッシュ全体を拒否できます。
- `update`: 更新されるブランチごとに1回実行されます。個々のブランチを拒否できます。
- `post-receive`: すべての参照が更新された後に実行されます。プッシュを拒否できませんが、フックが失敗した場合、エラーが発生する可能性があります。

`(pre-receive hook declined)`エラーは通常、`pre-receive`または`update`フックから発生します。問題を特定するには:

1. `(pre-receive hook declined)`メッセージの直前の出力を確認します。この出力には、プッシュが拒否された理由に関する情報が含まれていることがよくあります。次に例を示します:

   ```plaintext
   remote: GitLab: The default branch of a project cannot be deleted.
   ! [remote rejected] main (pre-receive hook declined)
   ```

1. フックが失敗した理由の詳細については、Gitalyログを確認してください:

   ```shell
   sudo grep PreReceiveHook /var/log/gitlab/gitaly/current | jq .
   ```

1. リポジトリにカスタムサーバーフックが構成されている場合は、カスタムフックコードに問題がないか確認してください。

事前受信フックの失敗の一般的な原因を以下に示します:

- デフォルトブランチ保護: デフォルトブランチを削除または強制的に更新するプッシュは拒否されます。これは、ソースリポジトリのデフォルトブランチがターゲットリポジトリと異なる場合に`git push --mirror`で発生します。
- プッシュルール: プッシュは、コミットメッセージの要件、ファイルサイズの制限、作成者のメール制限など、構成済みのプッシュルールに違反しています。
- カスタムサーバーフック: カスタムサーバーフックスクリプトがプッシュを拒否しました。カスタムフックコードとエラーメッセージをレビューします。
- タイムアウト: フックの実行に時間がかかりすぎて、強制終了されました。タイムアウトエラーについては、Gitalyログを確認してください。
- LFSオブジェクト: リポジトリに必要なGit LFSオブジェクトが見つかりません。

フックの失敗をユーザーが理解できるように、[カスタムエラーメッセージ](#custom-error-messages)を使用して、プッシュが拒否された理由に関する明確なフィードバックを提供します。カスタムエラーメッセージは、GitLab UIおよびユーザーのターミナルに表示されます。
