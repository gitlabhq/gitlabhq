---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: ターミナルでGitLab CLI（glab）を使用して、一般的なGitLabアクションを実行します。
title: GitLab CLI - `glab`
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

`glab`はオープンソースのGitLab CLIツールです。Gitやコードを処理しているターミナルでGitLabを直接利用でき、ウィンドウやブラウザータブを切り替える必要がありません。

- イシューを処理する。
- マージリクエストを操作する。
- 実行中のパイプラインをコマンドラインインターフェース（CLI）から直接監視する。

![コマンドの例](img/glabgettingstarted_v15_7.gif)

GitLab CLIは、`glab <command> <subcommand> [flags]`という形式の構造化されたコマンドを使用して、通常はGitLabのユーザーインターフェースから行う多くの操作を実行できます:

```shell
# Sign in
glab auth login --stdin < token.txt

# View a list of issues
glab issue list

# Create merge request for issue 123
glab mr create 123

# Check out the branch for merge request 243
glab mr checkout 243

# Watch the pipeline in progress
glab pipeline ci view

# View, approve, and merge the merge request
glab mr view
glab mr approve
glab mr merge
```

## コアコマンド {#core-commands}

- [`glab alias`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/alias): エイリアスの作成、一覧表示、削除を行います。
- [`glab api`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/api): 認証済みのGitLab APIにリクエストを送信します。
- [`glab auth`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/auth): CLIの認証状態を管理します。
- [`glab changelog`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/changelog): 変更履歴APIとやり取りします。
- [`glab check-update`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/check-update): CLIのアップデートを確認します。
- [`glab ci`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/ci): GitLab CI/CDパイプラインやジョブを操作します。
- [`glab cluster`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/cluster): Kubernetes向けGitLabエージェントとそのクラスターを管理します。
- [`glab completion`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/completion): Shell補完スクリプトを生成します。
- [`glab config`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/config): CLI設定を編集および取得します。
- [`glab deploy-key`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/deploy-key): デプロイキーを管理します。
- [`glab duo`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/duo): 自然言語からターミナルコマンドを生成します。
- [`glab incident`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/incident): GitLabのインシデントを操作します。
- [`glab issue`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/issue): GitLabイシューを操作します。
- [`glab iteration`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/iteration): イテレーション情報を取得します。
- [`glab job`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/job): GitLab CI/CDジョブを操作します。
- [`glab label`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/label): プロジェクトのラベルを管理します。
- [`glab mr`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/mr): マージリクエストを作成、表示、管理します。
- [`glab release`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/release): GitLabリリースを管理します。
- [`glab repo`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/repo): GitLabのリポジトリとプロジェクトを操作します。
- [`glab schedule`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/schedule): GitLab CI/CDのスケジュールを操作します。
- [`glab securefile`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/securefile): プロジェクトのセキュアファイルを管理します。
- [`glab snippet`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/snippet): スニペットを作成、表示、管理します。
- [`glab ssh-key`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/ssh-key): GitLabアカウントに登録されたSSHキーを管理します。
- [`glab stack`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/stack): スタックされた差分を作成、管理、操作します。
- [`glab token`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/token): 個人、プロジェクト、またはグループのトークンを管理します。
- [`glab user`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/user): GitLabユーザーアカウントを操作します。
- [`glab variable`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/variable): GitLabプロジェクトまたはグループの変数を管理します。
- [`glab version`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/version): CLIのバージョン情報を表示します。

## CLI用GitLab Duo {#gitlab-duo-for-the-cli}

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude 3 Haiku](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-haiku)
- [GitLab Duoセルフホストモデル](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

{{< history >}}

- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

GitLab CLIには、[GitLab Duo](../../user/gitlab_duo/_index.md)を利用する機能が含まれています。たとえば、次の機能があります:

- [`glab duo ask`](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/duo/ask.md)

作業中に`git`コマンドについて質問するには、次のように入力します:

- [`glab duo ask`](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/duo/ask.md)

`glab duo ask`コマンドは、忘れた`git`コマンドを思い出す手助けをしたり、他のタスクを実行するための`git`コマンドの使い方を提案したりします。

## コマンドラインインターフェース（CLI）をインストールする {#install-the-cli}

インストール手順は、[`glab`の`README`](https://gitlab.com/gitlab-org/cli/#installation)に記載されています。

## GitLabに対して認証する {#authenticate-with-gitlab}

GitLabアカウントに対して認証するには、`glab auth login`を実行します。`glab`は、`GITLAB_TOKEN`で設定されたトークンに従います。

`glab`は、安全な認証のために[1Password Shellプラグイン](https://developer.1password.com/docs/cli/shell-plugins/gitlab/)とも統合されています。

## 例 {#examples}

### ファイルから変数を読み込みCI/CDパイプラインを実行する {#run-a-cicd-pipeline-with-variables-from-a-file}

`glab ci run`コマンドに`-f`（`--variables-from-string`）フラグを指定して実行すると、外部ファイルに格納されている値を使用できます。たとえば、次のコードを`.gitlab-ci.yml`ファイルに追加すると、2つの変数を参照できます:

```yaml
stages:
  - build

# $EXAMPLE_VARIABLE_1 and $EXAMPLE_VARIABLE_2 are stored in another file
build-job:
  stage: build
  script:
    - echo $EXAMPLE_VARIABLE_1
    - echo $EXAMPLE_VARIABLE_2
    - echo $CI_JOB_ID
```

次に、これらの変数を格納する`variables.json`というファイルを作成します:

```json
[
  {
    "key": "EXAMPLE_VARIABLE_1",
    "value": "example value 1"
  },
  {
    "key": "EXAMPLE_VARIABLE_2",
    "value": "example value 2"
  }
]
```

`variables.json`の内容を含むCI/CDパイプラインを開始するには、次のコマンドを実行します。必要に応じてファイルのパスを編集してください:

```shell
$ glab ci run --variables-file /tmp/variables.json

$ echo $EXAMPLE_VARIABLE_1
example value 1
$ echo $EXAMPLE_VARIABLE_2
example value 2
$ echo $CI_JOB_ID
9811701914
```

### CLIをDocker認証情報ヘルパーとして使用する {#use-the-cli-as-a-docker-credential-helper}

GitLabの[コンテナレジストリ](../../user/packages/container_registry/_index.md)または[コンテナイメージ依存プロキシ](../../user/packages/dependency_proxy/_index.md)からイメージをプルする場合、CLIを[Docker認証情報ヘルパー](https://docs.docker.com/reference/cli/docker/login/#credential-helpers)として使用できます。認証情報ヘルパーを設定するには、次の手順に従います:

1. `glab auth login`を実行します。
1. サインインするGitLabインスタンスの種類を選択します。プロンプトが表示されたら、GitLabのホスト名を入力します。
1. サインイン方法で、`Web`を選択します。
1. コンテナレジストリおよびコンテナイメージプロキシで使用するドメインのカンマ区切りリストを入力します。GitLab.comにサインインすると、デフォルト値が自動入力されます。
1. 認証後、`glab auth configure-docker`を実行して、Docker設定の認証情報ヘルパーを初期化します。

## イシューを報告する {#report-issues}

[`gitlab-org/cli`リポジトリ](https://gitlab.com/gitlab-org/cli/-/issues/new)でイシューをオープンして、フィードバックを送信してください。

## 関連トピック {#related-topics}

- [コマンドラインインターフェース（CLI）をインストールする](https://gitlab.com/gitlab-org/cli/-/blob/main/README.md#installation)
- [ドキュメント](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source)
- [`cli`](https://gitlab.com/gitlab-org/cli/)プロジェクトの拡張ソースコード

## トラブルシューティング {#troubleshooting}

### `glab` 2.0.0の環境変数の変更点 {#environment-variable-changes-in-glab-200}

`glab`バージョン2.0.0以降、すべての`glab`環境変数には`GLAB_`というプレフィックスが付きます。この非推奨に関する詳細については、[イシュー7999](https://gitlab.com/gitlab-org/cli/-/issues/7999)を参照してください。

### 1Password Shellプラグインを使用すると`glab completion`コマンドが失敗する {#glab-completion-commands-fail-when-using-the-1password-shell-plugin}

[1Password Shellプラグイン](https://developer.1password.com/docs/cli/shell-plugins/gitlab/)はエイリアス`glab='op plugin run -- glab'`を追加しますが、これは`glab completion`コマンドと干渉する可能性があります。`glab completion`コマンドが失敗する場合は、補完を実行する前にエイリアスが展開されないようにShellを設定します:

- Zshの場合は、`~/.zshrc`ファイルを編集して次の行を追加します:

  ```plaintext
  setopt completealiases
  ```

- Bashの場合は、`~/.bashrc`ファイルを編集して次の行を追加します:

  ```plaintext
  complete -F _functionname glab
  ```

詳細については、1Password Shellプラグインの[イシュー122](https://github.com/1Password/shell-plugins/issues/122)を参照してください。

### コマンドが誤ったGitリモートを使用する {#commands-use-the-wrong-git-remote}

Gitリポジトリに複数のリモートがあり、誤ったリモートを選択した場合、コマンドがそのリモートにクエリすると空の結果が返されることがあります。この問題を修正するには、`glab`がそのリポジトリで参照するリモートを変更します:

1. ターミナルから`git config edit`を実行します。
1. `glab-resolved = base`が含まれる行を検索し、誤っている場合は削除します。
1. Git設定ファイルへの変更を保存します。
1. 使用するデフォルトを設定するには、次のコマンドを実行します。例の`origin`を編集し、優先するリモート名に置き換えてください:

   ```shell
   git config set --append remote.origin.glab-resolved base
   ```
