---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 変更内容に対するGitのブランチを作成
---

**ブランチ**とは、ブランチ作成時におけるリポジトリ内のファイルのコピーです。他のブランチに影響を与えることなく、自分のブランチで作業できます。メインのコードベースに変更内容を追加する準備ができたら、たとえば、`main`のように、ブランチをデフォルトブランチにマージできます。

ブランチは次の場合に使用します。

- コードをプロジェクトに追加したいが、正しく動作するかどうかわからない。
- 他の人とプロジェクトで共同作業をしていて、自分の作業が混同されないようにしたい。

## ブランチを作成する

ブランチを作成するには:

```shell
git checkout -b <name-of-branch>
```

GitLabは、問題を回避するために[ブランチの命名規則](../../user/project/repository/branches/_index.md#name-your-branch)を適用し、マージリクエストの作成を効率化するための[ブランチ命名パターン](../../user/project/repository/branches/_index.md#prefix-branch-names-with-a-number)を提供します。

## ブランチに切り替える

Gitでのすべての作業は、ブランチで行われます。ブランチを切り替えて、ファイルの状態を確認し、そのブランチで作業できます。

既存のブランチに切り替えるには:

```shell
git checkout <name-of-branch>
```

たとえば、`main`ブランチに変更するには:

```shell
git checkout main
```

## ブランチを最新の状態に保つ

あなたのブランチには、他のブランチからデフォルトブランチにマージされた変更が自動的に含まれることはありません。ブランチを作成した後にマージされた変更を含めるには、ブランチを手動で更新する必要があります。

デフォルトブランチの最新の変更でブランチを更新するには、次のいずれかを実行します。

- `git rebase`を実行して、デフォルトブランチに対してブランチを[リベース](git_rebase.md)します。変更をgit logでデフォルトブランチからの変更より後に表示する場合は、このコマンドを使用します。
- `git pull <remote-name> <default-branch-name>`を実行します。変更をデフォルトブランチからの変更とともにgit logに時系列順で表示したい場合、またはブランチを他の人と共有する場合は、このコマンドを使用します。`<remote-name>`の正しい値がわからない場合は、`git remote`を実行します。

## 関連トピック

- [ブランチ](../../user/project/repository/branches/_index.md)
- [タグ](../../user/project/repository/tags/_index.md)
