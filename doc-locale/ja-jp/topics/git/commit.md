---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Common commands and workflows.
title: 変更のステージング、コミット、プッシュ
---

リポジトリ内のファイルを変更すると、Gitはチェックアウトされたブランチの最新バージョンに対する変更を追跡します。Gitコマンドを使用して、変更内容を確認してブランチにコミットし、作業内容をGitLabにプッシュできます。

## ローカルの変更を追加してコミットする

変更をブランチに書き込む準備ができたら、変更をコミットできます。コミットには、変更に関する情報を記録したコメントが含まれており、通常はこれがブランチの新しい先端になります。

Gitは、移動、変更、または削除したファイルをコミットに自動的に含めません。これにより、一時ディレクトリのような変更やファイルを誤って含めることを防ぎます。変更をコミットに含めるには、`git add`でステージングします。

変更をステージングしてコミットするには:

1. リポジトリから、追加するファイルまたはディレクトリごとに`git add <file name or path>`を実行します。

   現在の作業ディレクトリ内のすべてのファイルをステージングするには、`git add .`を実行します。

1. ファイルがステージングに追加されたことを確認します。

   ```shell
   git status
   ```

   ファイルが緑色で表示されます。

1. ステージングされたファイルをコミットします。

   ```shell
   git commit -m "<comment that describes the changes>"
   ```

変更がブランチにコミットされます。

## すべての変更をコミット

次のように、すべての変更をステージングして、1つのコマンドでコミットできます。

```shell
git commit -a -m "<comment that describes the changes>"
```

コミットに、リモートリポジトリに記録したくないファイルが含まれないように注意してください。原則として、変更をコミットする前に、ローカルリポジトリの状態を常に確認してください。

## 変更をGitLabに送信する

すべてのローカルの変更をリモートリポジトリにプッシュするには:

```shell
git push <remote> <name-of-branch>
```

たとえば、ローカルコミットを`origin`リモートの`main`ブランチにプッシュするには:

```shell
git push origin main
```

Gitがリポジトリへのプッシュを許可しない場合があります。その場合は、代わりに[更新を強制](git_rebase.md#force-push-to-a-remote-branch)する必要があります。

## プッシュオプション

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ブランチに変更をプッシュする際に、クライアント側の[Gitプッシュオプション](https://git-scm.com/docs/git-push#Documentation/git-push.txt--oltoptiongt)を使用できます。Git 2.10以降では、Gitプッシュオプションを使用して、以下を実行します。

- [CIジョブをスキップ](#push-options-for-gitlab-cicd)
- [マージリクエストにプッシュ](#push-options-for-merge-requests)

Git 2.18 以降では、長形式（`--push-option`）か短縮した`-o`のいずれかを使用できます。

```shell
git push -o <push_option>
```

Git 2.10 - 2.17では、長形式を使用する必要があります。

```shell
git push --push-option=<push_option>
```

サーバー側のコントロールとベストプラクティスの実施については、[プッシュルール](../../user/project/repository/push_rules.md)と[サーバーフック](../../administration/server_hooks.md)を参照してください。

### GitLab CI/CDのプッシュオプション

プッシュオプションを使用すると、CI/CDパイプラインをスキップしたり、CI/CD変数を渡したりできます。

{{< alert type="note" >}}

プッシュオプションは、マージリクエストパイプラインでは使用できません。詳細については、[イシュー373212](https://gitlab.com/gitlab-org/gitlab/-/issues/373212)を参照してください。

{{< /alert >}}

| プッシュオプション                    | 説明 | 例 |
|--------------------------------|-------------|---------|
| `ci.input=<name>=<value>`      | 指定されたインプットでパイプラインを作成します。 | 例: `git push -o ci.input='stage=test' -o ci.input='security_scan=false'`。文字列の配列を使用した例: `ci.input='["string", "double", "quotes"]'` |
| `ci.skip`                      | 最新のプッシュに対してCI/CDパイプラインを作成しません。ブランチパイプラインのみをスキップし、[マージリクエストパイプライン](../../ci/pipelines/merge_request_pipelines.md)はスキップしません。このオプションでは、JenkinsなどのCI/CDインテグレーションのパイプラインをスキップしません。 | `git push -o ci.skip` |
| `ci.variable="<name>=<value>"` | プッシュによってCI/CDパイプラインが作成された場合、そのパイプラインに[CI/CD変数](../../ci/variables/_index.md)を提供します。[マージリクエストパイプライン](../../ci/pipelines/merge_request_pipelines.md)ではなく、ブランチパイプラインにのみ変数を渡します。 | `git push -o ci.variable="MAX_RETRIES=10" -o ci.variable="MAX_TIME=600"` |

### インテグレーションのプッシュオプション

プッシュオプションを使用して、インテグレーションCI/CDパイプラインをスキップできます。

| プッシュオプション                    | 説明 | 例 |
|--------------------------------|-------------|---------|
| `integrations.skip_ci`         | Atlassian Bamboo、Buildkite、Drone、Jenkins、JetBrains TeamCityなどのCI/CDインテグレーションのプッシュイベントをスキップします。[GitLab 16.2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123837)で導入されました。 | `git push -o integrations.skip_ci` |

### マージリクエストのプッシュオプション

Gitプッシュオプションは、変更をプッシュしながらマージリクエストのアクションを実行できます。

| プッシュオプション                                  | 説明 |
|----------------------------------------------|-------------|
| `merge_request.create`                       | プッシュされたブランチの新しいマージリクエストを作成します。 |
| `merge_request.target=<branch_name>`         | マージリクエストのターゲットを特定のブランチに設定します（例: `git push -o merge_request.target=branch_name`）。 |
| `merge_request.target_project=<project>`     | マージリクエストのターゲットを特定のアップストリームプロジェクトに設定します（例: `git push -o merge_request.target_project=path/to/project`）。[GitLab 16.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132475)で導入されました。 |
| `merge_request.merge_when_pipeline_succeeds` | パイプラインの成功時にマージリクエストが[マージ](../../user/project/merge_requests/auto_merge.md)されるように設定します。 |
| `merge_request.remove_source_branch`         | マージリクエストのマージ時に、ソースブランチを削除するように設定します。 |
| `merge_request.squash`                       | マージ時に、マージリクエストがすべてのコミットを単一コミットにスカッシュするよう設定します。[GitLab 17.2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158778)で導入されました。 |
| `merge_request.title="<title>"`              | マージリクエストのタイトルを設定します。例: `git push -o merge_request.title="The title I want"`。 |
| `merge_request.description="<description>"`  | マージリクエストの説明を設定します。例: `git push -o merge_request.description="The description I want"`。 |
| `merge_request.draft`                        | マージリクエストを下書きとしてマークします。例: `git push -o merge_request.draft`。[GitLab 15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/296673)で導入されました。 |
| `merge_request.milestone="<milestone>"`      | マージリクエストのマイルストーンを設定します。例: `git push -o merge_request.milestone="3.0"`。 |
| `merge_request.label="<label>"`              | ラベルをマージリクエストに追加します。ラベルが存在しない場合はラベルが作成されます。たとえば、ラベル2つの場合は次のようになります。`git push -o merge_request.label="label1" -o merge_request.label="label2"` |
| `merge_request.unlabel="<label>"`            | ラベルをマージリクエストから削除します。たとえば、ラベル2つの場合は次のようになります。`git push -o merge_request.unlabel="label1" -o merge_request.unlabel="label2"` |
| `merge_request.assign="<user>"`              | ユーザーをマージリクエストに割り当てます。ユーザー名またはユーザーIDに対応しています。たとえば、ユーザー2人の場合は次のようになります。`git push -o merge_request.assign="user1" -o merge_request.assign="user2"`ユーザー名のサポートは[GitLab 15.5](https://gitlab.com/gitlab-org/gitlab/-/issues/344276)で追加されました。 |
| `merge_request.unassign="<user>"`            | 割り当てられたユーザーをマージリクエストから削除します。ユーザー名またはユーザーIDに対応しています。たとえば、ユーザー2人の場合は次のようになります。`git push -o merge_request.unassign="user1" -o merge_request.unassign="user2"`ユーザー名のサポートは[GitLab 15.5](https://gitlab.com/gitlab-org/gitlab/-/issues/344276)で追加されました。 |

### シークレットプッシュ保護のプッシュオプション

プッシュオプションを使用して、[シークレットプッシュ保護](../../user/application_security/secret_detection/secret_push_protection/_index.md)をスキップできます。

| プッシュオプション                    | 説明 | 例 |
|--------------------------------|-------------|---------|
| `secret_push_protection.skip_all` | このプッシュのコミットでシークレットプッシュ保護を実行しません。 | `git push -o secret_push_protection.skip_all` |

### GitGuardianインテグレーションのプッシュオプション

同じ[シークレットプッシュ保護のプッシュオプション](#push-options-for-secret-push-protection)を使用して、GitGuardianシークレット検出をスキップできます。

| プッシュオプション                    | 説明 | 例 |
|--------------------------------|-------------|---------|
| `secret_detection.skip_all` | GitLab 17.2で非推奨になりました。代わりに`secret_push_protection.skip_all`を使用してください。 | `git push -o secret_detection.skip_all` |
| `secret_push_protection.skip_all` | GitGuardianシークレット検出を実行しません。 | `git push -o secret_push_protection.skip_all` |

### プッシュオプションの形式

プッシュオプションにスペースを含むテキストが必要な場合は、テキストを二重引用符（`"`）で囲みます。スペースがない場合は、引用符を省略できます。次に例を示します。

```shell
git push -o merge_request.label="Label with spaces"
git push -o merge_request.label=Label-with-no-spaces
```

プッシュオプションを組み合わせて複数のタスクを一度に実行するには、複数の`-o`（または`--push-option`）フラグを使用します。このコマンドは、新しいマージリクエストを作成し、ブランチ（`my-target-branch`）をターゲットにして、自動マージを設定します。

```shell
git push -o merge_request.create -o merge_request.target=my-target-branch -o merge_request.merge_when_pipeline_succeeds
```

### プッシュ用のGitエイリアスを作成する

プッシュオプションをGitコマンドに追加すると、コマンドが非常に長くなる可能性があります。同じプッシュオプションを頻繁に使用する場合は、そのオプションのGitエイリアスを作成します。Gitエイリアスは、長いGitコマンドのコマンドラインショートカットです。

[パイプラインの成功時にマージするGitプッシュオプション](#push-options-for-merge-requests)のGitエイリアスを作成して使用するには:

1. ターミナルウィンドウで次のコマンドを実行します。

   ```shell
   git config --global alias.mwps "push -o merge_request.create -o merge_request.target=main -o merge_request.merge_when_pipeline_succeeds"
   ```

1. デフォルトブランチ（`main`）をターゲットとして自動マージするローカルブランチのプッシュを実行するエイリアスを使用するには、次のコマンドを実行します。

   ```shell
   git mwps origin <local-branch-name>
   ```

## 関連トピック

- [一般的なGitコマンド](commands.md)
