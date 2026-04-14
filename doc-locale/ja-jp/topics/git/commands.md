---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: よく使用されるGitコマンドのリファレンスガイドで、codeコード、branchブランチ、commitコミット、およびrepositoryリポジトリのhistory履歴を管理するための例とベストプラクティスを掲載しています。
title: 一般的なGitコマンド
---

Gitコマンドを使用すると、開発ワークフロー全体で時間を節約できます。このリファレンスページには、コードの変更、ブランチの管理、履歴のレビューなど、一般的なタスクで頻繁に使用されるコマンドが記載されています。各コマンドセクションでは、正確な構文、実践的な例、追加ドキュメントへのリンクを提供します。

## `git add` {#git-add}

`git add`を使用して、ファイルをステージングエリアに追加します。

```shell
git add <file_path>
```

`git add .`を使用して現在の作業ディレクトリから変更を再帰的にステージングしたり、`git add --all`を使用してGitリポジトリ内のすべての変更をステージングしたりできます。

詳細については、[ブランチにファイルを追加する](add_files.md)を参照してください。

## `git blame` {#git-blame}

`git blame`を使用して、ファイルのどの部分をどのユーザーが変更したかについてレポートを作成します。

```shell
git blame <file_name>
```

`git blame -L <line_start>, <line_end>`を使用して、特定の行範囲を確認できます。

詳細については、[Git file blame](../../user/project/repository/files/git_blame.md)を参照してください。

### 例 {#example}

`example.txt`の5行目を最後に変更したユーザーは、次のスクリプトで確認できます。

```shell
$ git blame -L 5, 5 example.txt
123abc (Zhang Wei 2021-07-04 12:23:04 +0000 5)
```

## `git bisect` {#git-bisect}

`git bisect`により、二分探索を使用してバグを発生させたコミットを見つけます。

まず、「悪い」（バグを含む）コミットと「良い」（バグを含まない）コミットを特定します。

```shell
git bisect start
git bisect bad                 # Current version is bad
git bisect good v2.6.13-rc2    # v2.6.13-rc2 is known to be good
```

次に`git bisect`は、2つのポイント間にあるコミットを選択し、`git bisect good`または`git bisect bad`でコミットが「良い」か「悪い」かを識別するように求めます。コミットが見つかるまで、このプロセスを繰り返します。

## `git checkout` {#git-checkout}

`git checkout`を使用して、特定のブランチにスイッチします。

```shell
git checkout <branch_name>
```

新しいブランチを作成してスイッチするには、`git checkout -b <branch_name>`を使用します。

詳細については、[変更内容に対するGitのブランチを作成](branch.md)を参照してください。

## `git clone` {#git-clone}

`git clone`を使用して、既存のGitリポジトリをコピーします。

```shell
git clone <repository>
```

詳細については、[Gitリポジトリのクローンをローカルコンピューターに作成する](clone.md)を参照してください。

## `git commit` {#git-commit}

`git commit`を使用して、ステージされた変更をリポジトリにコミットします。

```shell
git commit -m "<commit_message>"
```

コミットメッセージに空白行が含まれている場合、最初の行はコミットの件名になり、残りはコミットの本文になります。件名を使用して変更を簡単に要約し、コミット本文を使用して詳細を追加します。

詳細については、[変更のステージング、コミット、プッシュ](commit.md)を参照してください。

## `git commit --amend` {#git-commit---amend}

`git commit --amend`を使用して、最新のコミットを変更します。

```shell
git commit --amend
```

## `git diff` {#git-diff}

`git diff`を使用して、ローカルのステージングに追加されていない変更と、クローンまたはプルした最新バージョンとの差分を表示します。

```shell
git diff
```

ローカルの変更とブランチの最新バージョンとの差分（diff）を表示できます。ブランチにコミットする前に、差分を表示してローカルの変更を把握します。

特定のブランチに対して変更を比較するには、次を実行します。

```shell
git diff <branch>
```

出力:

- 追加された行はプラス（`+`）で始まり、緑色で表示されます。
- 削除または変更された行はマイナス（`-`）で始まり、赤色で表示されます。

## `git init` {#git-init}

`git init`を使用して、Gitがリポジトリとして追跡するようにディレクトリを初期化します。

```shell
git init
```

設定ファイルとログファイルを含む`.git`ファイルがディレクトリに追加されます。`.git`ファイルを直接編集しないでください。

デフォルトブランチは`main`に設定されています。`git branch -m <branch_name>`を使用してデフォルトブランチの名前を変更するか、`git init -b <branch_name>`を使用して初期化できます。

## `git pull` {#git-pull}

`git pull`を使用して、最後にプロジェクトをクローンまたはプルした後にユーザーが行ったすべての変更を取得します。

```shell
git pull <optional_remote> <branch_name>
```

## `git push` {#git-push}

`git push`を使用して、リモートrefsを更新します。

```shell
git push
```

詳細については、[変更のステージング、コミット、プッシュ](commit.md)を参照してください。

## `git reflog` {#git-reflog}

`git reflog`を使用して、Git参照ログへの変更リストを表示します。

```shell
git reflog
```

デフォルトでは、`git reflog`は`HEAD`への変更リストを表示します。

詳細については、[変更を取り消す](undo.md)を参照してください。

## `git remote add` {#git-remote-add}

`git remote add`を使用して、GitLabのどのリモートリポジトリがローカルディレクトリにリンクされているかをGitに伝えます。

```shell
git remote add <remote_name> <repository_url>
```

リポジトリをクローンすると、デフォルトで、ソースリポジトリはリモート名`origin`に関連付けられます。

リモートの設定の詳細については、[フォーク](../../user/project/repository/forking_workflow.md)を参照してください。

## `git log` {#git-log}

`git log`を使用して、コミットのリストを時系列順に表示します。

```shell
git log
```

## `git show` {#git-show}

`git show`を使用して、Git内のオブジェクトに関する情報を表示します。

### 例 {#example-1}

コミット`HEAD`が指すものは、次のコマンドで確認できます。

```shell
$ git show HEAD
commit ab123c (HEAD -> main, origin/main, origin/HEAD)
```

## `git merge` {#git-merge}

`git merge`を使用して、あるブランチからの変更を別のブランチと結合します。

`git merge`の代替の詳細については、[マージコンフリクトをリベースおよび解決する](git_rebase.md)を参照してください。

### 例 {#example-2}

次の手順で、`feature_branch`の変更を`target_branch`に適用できます。

```shell
git checkout target_branch
git merge feature_branch
```

## `git rebase` {#git-rebase}

`git rebase`を使用して、ブランチのコミット履歴を書き換えます。

```shell
git rebase <branch_name>
```

`git rebase`を使用して、[マージコンフリクトを解決](git_rebase.md)できます。

ほとんどの場合、デフォルトブランチに対してリベースする必要があります。

## `git reset` {#git-reset}

`git reset`を使用して、コミットを元に戻し、コミット履歴を巻き戻して、以前のコミットから続行します。

```shell
git reset
```

詳細については、[変更を取り消す](undo.md)を参照してください。

## `git status` {#git-status}

`git status`を使用して、作業ディレクトリとステージングされたファイルの状態を表示します。

```shell
git status
```

ファイルを追加、変更、または削除すると、Gitで変更を表示できます。
