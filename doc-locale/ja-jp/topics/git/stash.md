---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 変更をスタッシュする
---

別のブランチに切り替えたいが、まだコミットする準備ができていない変更がある場合は、`git stash`を使用します。

## スタッシュエントリを作成する {#create-stash-entries}

デフォルトでは、`git stash`はワーキングディレクトリの追跡された変更と、ステージングに追加された変更を保存します。オプションを使用して、どの変更を含めるかを制御できます。

- 追跡対象の変更をスタッシュするには:

  ```shell
  git stash
  ```

- メッセージ付きで変更をスタッシュするには:

  ```shell
  git stash push -m "describe your changes here"
  ```

- 変更をスタッシュするが、ステージングに追加された変更は作業ディレクトリに残すには:

  ```shell
  git stash push -k
  ```

  `-k` (`--keep-index`) オプションは、変更をstashしますが、ワーキングディレクトリにもそれらを保持します。このオプションは、変更を一時的に保存したいが、引き続き作業を続けたい場合に使用します。
- 変更をスタッシュし、追跡対象外のファイルを含めるには:

  ```shell
  git stash push -u
  ```

  `-u` (`--include-untracked`) オプションは、Gitがまだ追跡していないファイルもstashします。このオプションがない場合、コミットされていない新しいファイルは作業ディレクトリに残ります。
- ステージングに追加された変更のみをスタッシュするには:

  ```shell
  git stash push -S
  ```

  `-S` (`--staged`) オプションは、ステージングされている変更のみをstashします。ステージングに追加された変更を保存し、ステージングされていない変更への作業を続けたい場合、このオプションを使用します。

## スタッシュエントリを適用する {#apply-stash-entries}

作業をスタッシュした後に多くの変更を加えると、スタッシュを適用する際に競合が発生する可能性があります。変更を適用する前に、これらの競合を解決する必要があります。

- 最新のスタッシュエントリを適用し、スタッシュに残すには:

  ```shell
  git stash apply
  ```

- 特定のスタッシュエントリを適用するには:

  ```shell
  git stash apply stash@{3}
  ```

- 最新のスタッシュエントリを適用し、スタッシュから削除するには:

  ```shell
  git stash pop
  ```

## スタッシュエントリを表示する {#view-stash-entries}

- すべてのスタッシュエントリを表示するには:

  ```shell
  git stash list
  ```

- 詳細を含むスタッシュエントリを表示するには:

  ```shell
  git stash list --stat
  ```

## スタッシュエントリを削除する {#delete-stash-entries}

- 最新のスタッシュエントリを削除するには:

  ```shell
  git stash drop
  ```

- 特定のスタッシュエントリを削除するには:

  ```shell
  git stash drop <name>
  ```

- すべてのスタッシュエントリを削除するには:

  ```shell
  git stash clear
  ```

## 例: スタッシュエントリの作成と適用 {#example-create-and-apply-a-stash-entry}

Gitスタッシュの使用を試すには:

1. Gitリポジトリ内のファイルを変更します。
1. 変更をスタッシュします:

   ```shell
   git stash push -m "Saving changes from edit"
   ```

1. スタッシュリストを表示します:

   ```shell
   git stash list
   ```

1. 保留中の変更がないことを確認します:

   ```shell
   git status
   ```

1. スタッシュされた変更を適用し、スタッシュからエントリを削除します:

   ```shell
   git stash pop
   ```

1. エントリが削除されたことを確認するために、スタッシュリストを表示します:

   ```shell
   git stash list
   ```

## 関連トピック {#related-topics}

- [Git stashの公式ドキュメント](https://git-scm.com/docs/git-stash)
