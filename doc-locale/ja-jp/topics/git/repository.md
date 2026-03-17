---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Gitリポジトリから不要な大きなファイルを削除してストレージサイズを削減するには、filter-repoコマンドを使用します。
title: リポジトリのサイズを削減する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Gitリポジトリのサイズは、パフォーマンスとストレージコストに大きく影響する可能性があります。圧縮、ハウスキーピング、その他の要因により、インスタンスごとに若干異なる場合があります。

リポジトリサイズの詳細については、以下を参照してください:

- [リポジトリサイズ](../../user/project/repository/repository_size.md)
  - [リポジトリサイズの計算方法](../../user/project/repository/repository_size.md#size-calculation)
  - [サイズとストレージの制限](../../user/project/repository/repository_size.md#size-and-storage-limits)
  - [GitLab UI](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size)を使用してリポジトリサイズを削減する方法

## リポジトリの履歴からファイルをパージ {#purge-files-from-repository-history}

この方法は、Gitの履歴全体から大きなファイルを削除するために使用します。

パスワードやキーなどの機密データをリポジトリから削除するのには適していません。ファイルの内容を含むコミットに関する情報はデータベースにキャッシュされ、リポジトリから削除された後も表示されたままになります。機密データを削除するには、[blobを削除](../../user/project/repository/repository_size.md#remove-blobs)で説明されている方法を使用してください。

前提条件: 

- [`git filter-repo`](https://github.com/newren/git-filter-repo/blob/main/INSTALL.md)をインストールする必要があります。
- オプション。[`git-sizer`](https://github.com/github/git-sizer#getting-started)をインストールします。

> [!warning]
> ファイルのパージは破壊的な操作です。続行する前に、リポジトリのバックアップがあることを確認してください。

GitLabリポジトリからファイルをパージするには:

1. リポジトリのコピーを含む[プロジェクトをエクスポートする](../../user/project/settings/import_export.md#export-a-project-and-its-data)と、ダウンロードされます。

   - 大規模なプロジェクトの場合は、[プロジェクトリレーションエクスポートAPI](../../api/project_relations_export.md)を使用できます。

1. バックアップを解凍して抽出します:

   ```shell
   tar xzf project-backup.tar.gz
   ```

1. `--bare`および`--mirror`オプションを使用して、リポジトリをクローンします:

   ```shell
   git clone --bare --mirror /path/to/project.bundle
   ```

1. `project.git`ディレクトリに移動します:

   ```shell
   cd project.git
   ```

1. リモートURLを更新します:

   ```shell
   git remote set-url origin https://gitlab.example.com/<namespace>/<project_name>.git
   ```

1. `git filter-repo`または`git-sizer`を使用してリポジトリを分析します:

   - `git filter-repo`: 

     ```shell
     git filter-repo --analyze
     head filter-repo/analysis/*-{all,deleted}-sizes.txt
     ```

   - `git-sizer`: 

     ```shell
     git-sizer
     ```

1. 次の`git filter-repo`オプションのいずれかを使用して、リポジトリの履歴をパージします:

   - 特定のファイルをパージするには、`--path`と`--invert-paths`を使用します:

     ```shell
     git filter-repo --path path/to/file.ext --invert-paths
     ```

   - たとえば10Mより大きいすべてのファイルをパージするには、`--strip-blobs-bigger-than`を使用します:

     ```shell
     git filter-repo --strip-blobs-bigger-than 10M
     ```

   詳細については、[`git filter-repo`のドキュメント](https://htmlpreview.github.io/?https://github.com/newren/git-filter-repo/blob/docs/html/git-filter-repo.html#EXAMPLES)を参照してください。

1. `commit-map`をバックアップします:

   ```shell
   cp filter-repo/commit-map ./_filter_repo_commit_map_$(date +%s)
   ```

1. ミラーフラグを解除します:

   ```shell
    git config --unset remote.origin.mirror
   ```

1. 強制プッシュで変更をプッシュします:

   ```shell
   git push origin --force 'refs/heads/*'
   git push origin --force 'refs/tags/*'
   git push origin --force 'refs/replace/*'
   ```

   参照の詳細については、Gitalyで使用されるGit参照を参照してください。

   > [!note]
   > この手順は、[保護ブランチ](../../user/project/repository/branches/protected.md)と[保護タグ](../../user/project/protected_tags.md)の場合は失敗します。続行するには、一時的に保護を削除します

1. 次の手順に進む前に、少なくとも30分待ちます。
1. [リポジトリのクリーンアップ](../../user/project/repository/repository_size.md#clean-up-repository)プロセスを実行します。このプロセスでは、30分以上経過したオブジェクトのみがクリーンアップされます。詳細については、[クリーンアップ後にスペースが解放されない](../../user/project/repository/repository_size.md#space-not-being-freed-after-cleanup)を参照してください。
