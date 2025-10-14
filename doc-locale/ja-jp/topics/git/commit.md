---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 一般的なコマンドとワークフロー。
title: 変更のステージング、コミット、プッシュ
---

リポジトリ内のファイルを変更すると、Gitはチェックアウトされたブランチの最新バージョンに対する変更を追跡します。Gitコマンドを使用して、変更内容をレビューしてブランチにコミットし、作業内容をGitLabにプッシュできます。

## ローカルの変更を追加してコミットする {#add-and-commit-local-changes}

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

### 良好なコミットメッセージを作成する {#write-a-good-commit-message}

[Git Commit Messageの書き方](https://cbea.ms/git-commit/)でChris Beamsが公開しているガイドラインは、良好なコミットメッセージの作成に役立ちます。

- コミットの件名と本文は、空白行で区切る必要があります。
- コミットの件名は、大文字で始める必要があります。
- コミットの件名は、72文字を超えてはなりません。
- コミットの件名の末尾にピリオドを付けてはなりません。
- コミットの本文は、1行あたり72文字を超えてはなりません。
- コミットの件名または本文に絵文字を含めてはなりません。
- 3つ以上のファイルにわたって30行以上の変更があるコミットは、コミットの本文でこれらの変更について記述する必要があります。
- イシュー、マイルストーン、およびマージリクエストには、短縮参照ではなく完全なURLを使用してください。これらはGitLabの外部ではプレーンテキストとして表示されます。
- マージリクエストに含めるコミットメッセージは10個以下にしてください。
- コミットの件名には、少なくとも3つの単語を含める必要があります。

## すべての変更をコミットする {#commit-all-changes}

次のように、すべての変更をステージングして、1つのコマンドでコミットできます。

```shell
git commit -a -m "<comment that describes the changes>"
```

コミットに、リモートリポジトリに記録したくないファイルが含まれないように注意してください。原則として、変更をコミットする前に、ローカルリポジトリの状態を常に確認してください。

## 変更をGitLabに送信する {#send-changes-to-gitlab}

すべてのローカルの変更をリモートリポジトリにプッシュするには:

```shell
git push <remote> <name-of-branch>
```

たとえば、ローカルコミットを`origin`リモートの`main`ブランチにプッシュするには:

```shell
git push origin main
```

Gitがリポジトリへのプッシュを許可しない場合があります。その場合は、代わりに[更新を強制](git_rebase.md#force-push-to-a-remote-branch)する必要があります。

## プッシュオプション {#push-options}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ブランチに変更をプッシュする際に、クライアント側の[Gitプッシュオプション](https://git-scm.com/docs/git-push#Documentation/git-push.txt--oltoptiongt)を使用できます。Git 2.10以降では、Gitプッシュオプションを使用して、以下を実行します。

- [CIジョブをスキップ](#push-options-for-gitlab-cicd)
- [マージリクエストにプッシュ](#push-options-for-merge-requests)

Git 2.18以降では、長形式（`--push-option`）か短縮した`-o`のいずれかを使用できます。

```shell
git push -o <push_option>
```

Git 2.10～2.17では、長形式を使用する必要があります。

```shell
git push --push-option=<push_option>
```

サーバー側のコントロールとベストプラクティスの実施については、[プッシュルール](../../user/project/repository/push_rules.md)と[サーバーフック](../../administration/server_hooks.md)を参照してください。

### GitLab CI/CDのプッシュオプション {#push-options-for-gitlab-cicd}

プッシュオプションを使用すると、CI/CDパイプラインをスキップしたり、CI/CD変数を渡したりできます。

{{< alert type="note" >}}

プッシュオプションは、マージリクエストパイプラインでは使用できません。詳細については、[イシュー373212](https://gitlab.com/gitlab-org/gitlab/-/issues/373212)を参照してください。

{{< /alert >}}

| プッシュオプション                    | 説明 | 例 |
|--------------------------------|-------------|---------|
| `ci.input=<name>=<value>`      | パイプラインにインプット変数を渡します。 | `git push -o ci.input='stage=test' -o ci.input='security_scan=false'`配列のインプット: `git push -o ci.input='my_array=["string", "double", "quotes"]'` |
| `ci.skip`                      | このプッシュのパイプラインをスキップします。ブランチのパイプラインにのみ影響し、[マージリクエストパイプライン](../../ci/pipelines/merge_request_pipelines.md)には影響しません。JenkinsのようなCI/CDインテグレーションはスキップしません。 | `git push -o ci.skip` |
| `ci.variable="<name>=<value>"` | パイプラインの[CI/CD変数](../../ci/variables/_index.md)を設定します。ブランチのパイプラインにのみ影響し、[マージリクエストパイプライン](../../ci/pipelines/merge_request_pipelines.md)には影響しません。 | `git push -o ci.variable="MAX_RETRIES=10" -o ci.variable="MAX_TIME=600"` |

### インテグレーションのプッシュオプション {#push-options-for-integrations}

プッシュオプションを使用すると、インテグレーションCI/CDパイプラインをスキップできます。

| プッシュオプション                    | 説明 | 例 |
|--------------------------------|-------------|---------|
| `integrations.skip_ci`         | Atlassian Bamboo、Buildkite、Drone、Jenkins、JetBrains TeamCityなどのCI/CDインテグレーションのプッシュイベントをスキップします。[GitLab 16.2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123837)で導入されました。 | `git push -o integrations.skip_ci` |

### マージリクエストのプッシュオプション {#push-options-for-merge-requests}

Gitプッシュオプションは、変更をプッシュしながらマージリクエストのアクションを実行できます。

| プッシュオプション                                  | 説明 |
|----------------------------------------------|-------------|
| `merge_request.create`                       | プッシュされたブランチの新しいマージリクエストを作成します。デフォルトブランチからプッシュする場合は、マージリクエストを作成するために、`merge_request.target`オプションを使用してターゲットブランチを指定する必要があります。 |
| `merge_request.target=<branch_name>`         | マージリクエストのターゲットを特定のブランチに設定します（例: `git push -o merge_request.target=branch_name`）。デフォルトブランチからマージリクエストを作成する際に必要です。 |
| `merge_request.target_project=<project>`     | マージリクエストのターゲットを特定のアップストリームプロジェクトに設定します（例: `git push -o merge_request.target_project=path/to/project`）。[GitLab 16.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132475)で導入されました。 |
| `merge_request.merge_when_pipeline_succeeds` | GitLab 17.11で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/185368)となり、`auto_merge`オプションが推奨されます。 |
| `merge_request.auto_merge` | [自動マージ](../../user/project/merge_requests/auto_merge.md)するようにマージリクエストを設定します。 |
| `merge_request.remove_source_branch`         | マージリクエストのマージ時に、ソースブランチを削除するように設定します。 |
| `merge_request.squash`                       | マージ時に、マージリクエストがすべてのコミットを単一コミットにスカッシュするよう設定します。[GitLab 17.2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158778)で導入されました。 |
| `merge_request.title="<title>"`              | マージリクエストのタイトルを設定します。例: `git push -o merge_request.title="The title I want"`。 |
| `merge_request.description="<description>"`  | マージリクエストの説明を設定します。例: `git push -o merge_request.description="The description I want"`。 |
| `merge_request.draft`                        | マージリクエストをドラフトとしてマークします。例: `git push -o merge_request.draft`。 |
| `merge_request.milestone="<milestone>"`      | マージリクエストのマイルストーンを設定します。例: `git push -o merge_request.milestone="3.0"`。 |
| `merge_request.label="<label>"`              | ラベルをマージリクエストに追加します。ラベルが存在しない場合はラベルが作成されます。たとえば、ラベル2つの場合は次のようになります。`git push -o merge_request.label="label1" -o merge_request.label="label2"` |
| `merge_request.unlabel="<label>"`            | ラベルをマージリクエストから削除します。たとえば、ラベル2つの場合は次のようになります。`git push -o merge_request.unlabel="label1" -o merge_request.unlabel="label2"` |
| `merge_request.assign="<user>"`              | ユーザーをマージリクエストに割り当てます。ユーザー名またはユーザーIDに対応しています。たとえば、ユーザー2人の場合は次のようになります。`git push -o merge_request.assign="user1" -o merge_request.assign="user2"`|
| `merge_request.unassign="<user>"`            | 割り当てられたユーザーをマージリクエストから削除します。ユーザー名またはユーザーIDに対応しています。たとえば、ユーザー2人の場合は次のようになります。`git push -o merge_request.unassign="user1" -o merge_request.unassign="user2"` |

### シークレットプッシュ保護のプッシュオプション {#push-options-for-secret-push-protection}

プッシュオプションを使用すると、[シークレットプッシュ保護](../../user/application_security/secret_detection/secret_push_protection/_index.md)をスキップできます。

| プッシュオプション                    | 説明 | 例 |
|--------------------------------|-------------|---------|
| `secret_push_protection.skip_all` | このプッシュのコミットにシークレットプッシュ保護を実行しません。 | `git push -o secret_push_protection.skip_all` |

### セキュリティポリシーのプッシュオプション {#push-options-for-security-policy}

プッシュオプションを使用すると、[セキュリティポリシーを回避](../../user/application_security/policies/merge_request_approval_policies.md#access-token-and-service-account-exceptions)できます。

| プッシュオプション                    | 説明 | 例 |
|--------------------------------|-------------|---------|
| `security_policy.bypass_reason` | セキュリティポリシーのバイパス理由を設定します。 | `git push -o security_policy.bypass_reason="Hot fix"` |

### GitGuardianインテグレーションのプッシュオプション {#push-options-for-gitguardian-integration}

同じ[シークレットプッシュ保護のプッシュオプション](#push-options-for-secret-push-protection)を使用すると、GitGuardianシークレット検出をスキップできます。

| プッシュオプション                    | 説明 | 例 |
|--------------------------------|-------------|---------|
| `secret_detection.skip_all` | GitLab 17.2で非推奨になりました。代わりに`secret_push_protection.skip_all`を使用してください。 | `git push -o secret_detection.skip_all` |
| `secret_push_protection.skip_all` | GitGuardianシークレット検出を実行しません。 | `git push -o secret_push_protection.skip_all` |

### プッシュオプションの形式 {#formats-for-push-options}

プッシュオプションにスペースを含むテキストが必要な場合は、テキストを二重引用符（`"`）で囲みます。スペースがない場合は、引用符を省略できます。次に例を示します。

```shell
git push -o merge_request.label="Label with spaces"
git push -o merge_request.label=Label-with-no-spaces
```

プッシュオプションを組み合わせて複数のタスクを一度に実行するには、複数の`-o`（または`--push-option`）フラグを使用します。このコマンドは、新しいマージリクエストを作成し、ブランチ（`my-target-branch`）をターゲットにして、自動マージを設定します。

```shell
git push -o merge_request.create -o merge_request.target=my-target-branch -o merge_request.auto_merge
```

異なるブランチをターゲットとして、デフォルトブランチから新しいマージリクエストを作成するには:

```shell
git push -o merge_request.create -o merge_request.target=feature-branch
```

### プッシュ用のGitエイリアスを作成する {#create-git-aliases-for-pushing}

プッシュオプションをGitコマンドに追加すると、コマンドが非常に長くなる可能性があります。同じプッシュオプションを頻繁に使用する場合は、そのオプションのGitエイリアスを作成します。Gitエイリアスは、長いGitコマンドのコマンドラインショートカットです。

[自動マージGitプッシュオプション](#push-options-for-merge-requests)のGitエイリアスを作成して使用するには:

1. ターミナルウィンドウで次のコマンドを実行します。

   ```shell
   git config --global alias.mwps "push -o merge_request.create -o merge_request.target=main -o merge_request.auto_merge"
   ```

1. デフォルトブランチ（`main`）をターゲットとして自動マージするローカルブランチのプッシュを実行するエイリアスを使用するには、次のコマンドを実行します。

   ```shell
   git mwps origin <local-branch-name>
   ```

## 関連トピック {#related-topics}

- [一般的なGitコマンド](commands.md)
