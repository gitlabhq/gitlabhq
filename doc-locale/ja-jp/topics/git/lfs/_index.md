---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Use Git LFS to manage binary assets, like images and video, without bloating your Git repository's size.
title: Git Large File Storage (LFS)
---

Git Large File Storage (LFS)は、Gitリポジトリが大きなバイナリファイルを効率的に管理する際に役立つ、オープンソースのGit拡張機能です。Gitは、テキストファイルへの変更を追跡する場合と同じ方法で、バイナリファイル（オーディオ、ビデオ、画像ファイルなど）への変更を追跡することができません。テキストベースのファイルはプレーンテキストの差分を生成できますが、バイナリファイルに変更を加える場合は、Gitがリポジトリ内のファイルを完全に置き換える必要があります。大容量ファイルを繰り返し変更すると、リポジトリのサイズが大きくなります。時間の経過とともに、このサイズの増加によって\`clone\`、\`fetch\`、\`pull\`などの通常のGitオペレーションが遅くなる可能性があります。

Git LFSを使用して、大容量のバイナリファイルをGitリポジトリの外部に保存し、Gitが管理するための小さなテキストベースのポインターのみを残します。Git LFSを使用してリポジトリにファイルを追加すると、GitLabは以下を実行します。

1. Gitリポジトリの代わりに、プロジェクトの設定済みオブジェクトストレージにファイルを追加する。
1. 大容量ファイルの代わりに、Gitリポジトリにポインターを追加する。ポインターには、次のようなファイルに関する情報が含まれています。

   ```plaintext
   version https://git-lfs.github.com/spec/v1
   oid sha256:lpca0iva5kpz9wva5rgsqsicxrxrkbjr0bh4sy6rz08g2c4tyc441rto5j5bctit
   size 804
   ```

   - **バージョン** \- 使用しているGit LFS仕様のバージョン
   - **OID** \- 使用されたハッシュ方式と、`{hash-method}:{hash}`形式の一意のオブジェクトID。
   - **サイズ** \- ファイルサイズ（バイト単位）。

1. ストレージサイズやLFSオブジェクトストレージなどのプロジェクトの統計を再計算するジョブをキューに追加します。LFSオブジェクトストレージは、リポジトリに関連付けられているすべてのLFSオブジェクトのサイズの合計です。

Git LFSで管理されるファイルには、ファイル名の横に**LFS**バッジが表示されます。

![Git LFSトラッキングステータス](img/lfs_badge_v16_0.png)

Git LFSクライアントは、HTTP基本認証を使用し、HTTPS経由でサーバーと通信します。リクエストを認証すると、Git LFSクライアントは、大容量ファイルを取得（またはプッシュ）する場所に関する指示を受け取ります。

Gitリポジトリのサイズは小さいままなので、リポジトリのサイズ制限に準拠することができます。詳細については、[GitLab Self-Managed向け](../../../administration/settings/account_and_limit_settings.md#repository-size-limit)および[GitLab SaaS向け](../../../user/gitlab_com/_index.md#account-and-limit-settings)のリポジトリサイズの制限を参照してください。

## Git LFSはフォークでどのように機能するのか

リポジトリをフォークすると、フォークした時点で存在していたアップストリームリポジトリの既存のLFSオブジェクトがフォークに含まれます。新しいLFSオブジェクトをフォークに追加した場合、それらのオブジェクトはフォークだけに属し、アップストリームリポジトリには属しません。オブジェクトストレージの合計は、フォークでのみ増加します。

フォークからアップストリームプロジェクトへのマージリクエストを作成し、そのマージリクエストに新しいGit LFSオブジェクトが含まれている場合、GitLabはマージ後に新しいLFSオブジェクトを_アップストリーム_プロジェクトに関連付けます。

## プロジェクトのGit LFSを設定する

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabでは、GitLab Self-ManagedとGitLab SaaSの両方で、Git LFSがデフォルトで有効になっています。サーバー設定とプロジェクト固有の設定の両方を利用できます。

- リモートオブジェクトストレージの設定など、インスタンスのGit LFSを設定するには、「[GitLab Git Large File Storage (LFS)を管理する](../../../administration/lfs/_index.md)」を参照してください。
- 特定のプロジェクトのGit LFSを設定するには、以下を実行します。

  1. リポジトリのローカルコピーのルートディレクトリで、`git lfs install`を実行します。このコマンドにより、以下が追加されます。
     - リポジトリへのpre-push Gitフック。
     - 個々のファイルとファイルタイプを追跡する[`.gitattributes`ファイル](../../../user/project/repository/files/git_attributes.md)。
  1. Git LFSで追跡するファイルとファイルの種類を追加します。

## プロジェクトのGit LFSを有効または無効にする

Git LFSは、GitLab Self-ManagedとGitLab SaaSの両方で、デフォルトで有効になっています。

前提要件:

- プロジェクトのデベロッパーロール以上を持っている必要があります。

プロジェクトのGit LFSを有効または無効にするには、以下を実行します。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを検索します。
1. **設定 > 一般**を選択します。
1. **可視性、プロジェクトの機能、権限**セクションを展開します。
1. **Git Large File Storage (LFS)**の切り替えを選択します。
1. **変更を保存**を選択します。

## ファイルを追加して追跡する

Git LFSには大容量ファイルを追加することができます。これにより、Gitリポジトリ内のファイルを管理することができます。Git LFSでファイルを追跡すると、ファイルはGit内のテキストポインターに置き換えられ、リモートサーバーに保存されます。詳細については、「[Git LFS](../../git/file_management.md#git-lfs)」を参照してください。

## Git LFSを使用するリポジトリを複製する

Git LFSを使用するリポジトリを複製すると、GitはLFSで追跡したファイルを検出し、HTTPS経由で複製します。`git clone`を`user@hostname.com:group/project.git`などのSSH URLで実行する場合は、HTTPS認証のためにGitLab認証情報を再度入力する必要があります。

デフォルトでは、GitがSSH経由でリポジトリと通信する場合でも、Git LFSオペレーションはHTTPS経由で実行されます。GitLab 17.2で、[LFSの純粋なSSHサポート](https://gitlab.com/groups/gitlab-org/-/epics/11872)が導入されました。この機能を有効にする方法については、「[純粋なSSH転送プロトコル](../../../administration/lfs/_index.md#pure-ssh-transfer-protocol)」を参照してください。

すでに複製したリポジトリの新しいLFSオブジェクトを取得するには、次のコマンドを実行します。

```shell
git lfs fetch origin main
```

## 既存のリポジトリをGit LFSに移行する

Git LFSを使用して既存のGitリポジトリを移行する方法については、「[`git-lfs-migrate`ドキュメント](https://github.com/git-lfs/git-lfs/blob/main/docs/man/git-lfs-migrate.adoc)」を参照してください。

## リポジトリの履歴からGit LFSファイルを削除する

Git LFSでファイルの追跡を解除することと、ファイルを削除することの違いを理解しておくことが重要です。

- **追跡解除**: ファイルはディスクとリポジトリの履歴に残ります。ユーザーが履歴ブランチまたはタグをチェックアウトする場合にも、ファイルのLFSバージョンが必要になります。
- **削除**: ファイルは削除されますが、リポジトリの履歴に残ります。

Git LFSで追跡したファイルを削除するには、「[ファイルを削除する](../undo.md#remove-a-file-from-a-repository)」を参照してください。

ファイルの過去と現在のすべての履歴を完全に削除するには、「[機密情報を処理する](../undo.md#handle-sensitive-information)」を参照してください。

{{< alert type="warning" >}}

ファイルの履歴を削除する場合は、Gitの履歴の書き換えが必要です。このアクションは破壊的であり、元に戻すことはできません。

{{< /alert >}}

## 大きなファイルを削除した後にリポジトリのサイズを縮小する

リポジトリの履歴から大きなファイルを削除してリポジトリの合計サイズを縮小する必要がある場合は、「[リポジトリのサイズを縮小する](../../../user/project/repository/repository_size.md#methods-to-reduce-repository-size)」を参照してください。

## 関連トピック

- Git LFSを使用して[排他的なファイルのロック](../file_management.md#configure-file-locks)を設定します。
- ブログ投稿: [Git LFS入門](https://about.gitlab.com/blog/2017/01/30/getting-started-with-git-lfs-tutorial/)
- [Git LFSとGit](../../git/file_management.md#git-lfs)
- [Git LFSデベロッパー向けの情報](../../../development/lfs.md)
- GitLab Self-Managed用の[Git Large File Storage (LFS)の管理](../../../administration/lfs/_index.md)
- [Git LFSのトラブルシューティング](troubleshooting.md)
- [`.gitattributes`ファイル](../../../user/project/repository/files/git_attributes.md)
