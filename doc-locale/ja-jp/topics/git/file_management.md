---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 一般的なコマンドとワークフロー。
title: ファイル管理
---

Gitは、変更の追跡、他のユーザーとのコラボレーション、および大きなファイルを効率的に管理するのに役立つファイル管理機能を提供します。

## ファイル履歴 {#file-history}

`git log`を使用して、ファイルの完全な履歴を表示し、それが時間の経過とともにどのように変化したかを理解します。ファイル履歴には、次の情報が表示されます:

- 各変更の作成者。
- 各変更の日時。
- 各コミットで行われた特定の変更。

たとえば、`gitlab`ルートディレクトリにある`CONTRIBUTING.md`ファイルに関する`history`情報を表示するには、次を実行します:

```shell
git log CONTRIBUTING.md
```

出力例: 

```shell
commit b350bf041666964c27834885e4590d90ad0bfe90
Author: Nick Malcolm <nmalcolm@gitlab.com>
Date:   Fri Dec 8 13:43:07 2023 +1300

    Update security contact and vulnerability disclosure info

commit 8e4c7f26317ff4689610bf9d031b4931aef54086
Author: Brett Walker <bwalker@gitlab.com>
Date:   Fri Oct 20 17:53:25 2023 +0000

    Fix link to Code of Conduct

    and condense some of the verbiage
```

## ファイルに対する以前の変更を確認する {#check-previous-changes-to-a-file}

`git blame`を使用して、ファイルに対する最後の変更を誰がいつ行ったかを確認します。これにより、ファイルの内容のコンテキストを理解し、競合を解決し、特定の変更の責任者を特定できます。

ローカルディレクトリ内の`README.md`ファイルに関する`blame`情報を検索する場合:

1. ターミナルまたはコマンドプロンプトを開きます。
1. Gitリポジトリに移動します。
1. 次のコマンドを実行します:

   ```shell
   git blame README.md
   ```

1. 結果ページをナビゲートするには、<kbd>Space</kbd>キーを押します。
1. 結果を終了するには、<kbd>Q</kbd>キーを押します。

この出力は、各行のコミットSHA、作成者、および日付を示す注釈付きでファイルの内容を表示します。次に例を示します:

```shell
58233c4f1054c (Dan Rhodes           2022-05-13 07:02:20 +0000  1) ## Contributor License Agreement
b87768f435185 (Jamie Hurewitz       2017-10-31 18:09:23 +0000  2)
8e4c7f26317ff (Brett Walker         2023-10-20 17:53:25 +0000  3) Contributions to this repository are subject to the
58233c4f1054c (Dan Rhodes           2022-05-13 07:02:20 +0000  4)
```

## Git LFS {#git-lfs}

Git Large File Storageは、Gitリポジトリ内の大きなファイルを管理するのに役立つ拡張機能です。大きなファイルをGit内のテキストポインターに置き換え、ファイルの内容をリモートリポジトリに保存します。

前提要件: 

- お使いのオペレーティングシステムに対応する[Git Large File Storage用CLI拡張機能](https://git-lfs.com)の適切なバージョンをダウンロードしてインストールします。
- [Git Large File Storageを使用するようにプロジェクトを構成](lfs/_index.md)します。
- Git Large File Storageプリプッシュフックをインストールします。これを行うには、リポジトリのルートディレクトリで`git lfs install`を実行します。

### ファイルを追加して追跡する {#add-and-track-files}

大きなファイルをGitリポジトリに追加し、Git Large File Storageで追跡するには:

1. 特定のタイプのすべてのファイルに対する追跡を構成します。`iso`を目的のファイルタイプに置き換えます:

   ```shell
   git lfs track "*.iso"
   ```

   このコマンドは、Git Large File StorageでISOファイルを処理するための手順が記載された`.gitattributes`ファイルを作成します。次の行が`.gitattributes`ファイルに追加されます:

   ```plaintext
   *.iso filter=lfs -text
   ```

1. そのタイプのファイル`.iso`をリポジトリに追加します。
1. `.gitattributes`ファイルと`.iso`ファイルの両方に対する変更を追跡します:

   ```shell
   git add .
   ```

1. 両方のファイルが追加されていることを確認します:

   ```shell
   git status
   ```

   `.gitattributes`ファイルは、コミットに含める必要があります。含まれていない場合、GitはGit Large File StorageでISOファイルを追跡しません。

   {{< alert type="note" >}}

   変更するファイルが`.gitignore`ファイルにリストされていないことを確認してください。リストされている場合、Gitは変更をローカルでコミットしますが、アップストリームリポジトリにプッシュしません。

   {{< /alert >}}

1. 両方のファイルをリポジトリのローカルコピーにコミットします:

   ```shell
   git commit -m "Add an ISO file and .gitattributes"
   ```

1. 変更をアップストリームにプッシュします。`main`をブランチの名前に置き換えます:

   ```shell
   git push origin main
   ```

1. マージリクエストを作成します。

{{< alert type="note" >}}

Git Large File Storageの追跡に新しいファイルタイプを追加すると、このタイプの既存のファイルはGit Large File Storageに変換されません。このタイプのファイルのうち、追跡を開始した後にのみ追加されたファイルがGit Large File Storageに追加されます。`git lfs migrate`を使用して、既存のファイルを変換してGit Large File Storageを使用するようにします。

{{< /alert >}}

### ファイルの追跡を停止する {#stop-tracking-a-file}

Git Large File Storageでのファイルの追跡を停止すると、ファイルはリポジトリの履歴の一部であるため、ディスク上に残ります。

Git Large File Storageでのファイルの追跡を停止するには:

1. `git lfs untrack`コマンドを実行し、ファイルへのパスを指定します:

   ```shell
   git lfs untrack doc/example.iso
   ```

1. `touch`コマンドを使用して、標準ファイルに変換します:

   ```shell
   touch doc/example.iso
   ```

1. ファイルへの変更を追跡します:

   ```shell
   git add .
   ```

1. 変更をコミットしてプッシュする
1. マージリクエストを作成し、レビューをリクエストします。
1. リクエストをターゲットブランチにマージします。

{{< alert type="note" >}}

`git lfs untrack`で追跡せずに、Git Large File Storageで追跡されたオブジェクトを削除すると、オブジェクトは`git status`で`modified`として表示されます。

{{< /alert >}}

### 単一タイプのすべてのファイルの追跡を停止する {#stop-tracking-all-files-of-a-single-type}

Git Large File Storageで特定のタイプのすべてのファイルの追跡を停止するには:

1. `git lfs untrack`コマンドを実行し、追跡を停止するファイルタイプを指定します:

   ```shell
   git lfs untrack "*.iso"
   ```

1. `touch`コマンドを使用して、ファイルを標準ファイルに変換します:

   ```shell
   touch *.iso
   ```

1. ファイルへの変更を追跡します:

   ```shell
   git add .
   ```

1. 変更をコミットしてプッシュする
1. マージリクエストを作成し、レビューをリクエストします。
1. リクエストをターゲットブランチにマージします。

## 排他的なファイルのロック {#exclusive-file-locks}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

排他的なファイルのロックは、競合を防ぎ、一度に1人だけがファイルを編集できるようにします。これは、次のような場合に適したオプションです:

- マージできないバイナリファイル。たとえば、設計ファイルやビデオ。
- 編集時に排他的アクセスを必要とするファイル。

排他的なファイルのロックは、リポジトリ内のすべてのブランチに適用されます。ファイルをデフォルトブランチでのみロックする必要がある場合は、代わりに[デフォルトブランチのファイルとディレクトリのファイルのロック](../../user/project/file_lock.md#default-branch-file-and-directory-locks)を使用してください。

前提要件: 

- [Git Large File Storageがインストールされている](lfs/_index.md)必要があります。
- プロジェクトのメンテナーロールを持っている必要があります。

### ファイルのロックを構成する {#configure-file-locks}

特定のファイルタイプのファイルのロックを構成するには:

1. `--lockable`オプションを指定して`git lfs track`コマンドを使用します。たとえば、PNGファイルを構成するには:

   ```shell
   git lfs track "*.png" --lockable
   ```

   このコマンドは、次の内容で`.gitattributes`ファイルを作成または更新します:

    ```plaintext
    *.png filter=lfs diff=lfs merge=lfs -text lockable
    ```

1. 変更を有効にするには、`.gitattributes`ファイルをリモートリポジトリにプッシュします。

{{< alert type="note" >}}

ファイルタイプがロック可能として登録されると、自動的に読み取り専用としてマークされます。

{{< /alert >}}

#### LFSなしでファイルのロックを構成する {#configure-file-locks-without-lfs}

Git Large File Storageを使用せずに、ファイルタイプをロック可能として登録するには:

1. `.gitattributes`ファイルを手動で編集する:

   ```shell
   *.pdf lockable
   ```

1. `.gitattributes`ファイルをリモートリポジトリにプッシュします。

### ファイルのロックとロック解除 {#lock-and-unlock-files}

排他的なファイルのロックでファイルをロックまたはロック解除するには:

1. リポジトリディレクトリでターミナルウィンドウを開きます。
1. 次のいずれかのコマンドを実行します:

   {{< tabs >}}

   {{< tab title="ファイルのロック" >}}

   ```shell
   git lfs lock path/to/file.png
   ```

   {{< /tab >}}

   {{< tab title="ファイルのロック解除" >}}

   ```shell
   git lfs unlock path/to/file.png
   ```

   {{< /tab >}}

   {{< tab title="IDでファイルのロック解除" >}}

   ```shell
   git lfs unlock --id=123
   ```

   {{< /tab >}}

   {{< tab title="強制的にファイルのロックを解除する" >}}

   ```shell
   git lfs unlock --id=123 --force
   ```

   {{< /tab >}}

   {{< /tabs >}}

### ロックされたファイルを表示する {#view-locked-files}

ロックされたファイルを表示するには:

1. リポジトリでターミナルウィンドウを開きます。
1. 次のコマンドを実行します:

   ```shell
   git lfs locks
   ```

   出力には、ロックされたファイル、ロックしたユーザー、およびファイルIDがリストされます。

GitLab UIの場合:

- リポジトリファイルツリーには、Git Large File Storageで追跡されたファイルのLFSバッジが表示されます。
- 排他的にロックされたファイルには、南京錠アイコンが表示されます。

{{< alert type="note" >}}

排他的にロックされたファイルの名前を変更すると、ロックは失われます。ロックされた状態を維持するには、再度ロックする必要があります。

{{< /alert >}}

### ファイルのロックと編集 {#lock-and-edit-a-file}

ファイルをロックし、編集し、必要に応じてロックを解除するには:

1. ファイルをロックします:

   ```shell
   git lfs lock <file_path>
   ```

1. ファイルを編集します。
1. オプション。完了したら、ファイルのロックを解除します:

   ```shell
   git lfs unlock <file_path>
   ```

## 関連トピック {#related-topics}

- [GitLab UIでのファイル管理](../../user/project/repository/files/_index.md)
- [Git Large File Storage (LFS) ドキュメント](lfs/_index.md)
- [ファイルのロック](../../user/project/file_lock.md)
