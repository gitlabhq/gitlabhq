---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 無料プッシュの制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

新しいファイルをFreeティアのプロジェクトにプッシュすると、ファイルごとに100MiBの制限が適用されます。

100MiB以上の新しいファイルがFreeティアのプロジェクトにプッシュされると、エラーが表示されます。例: 

```shell
Enumerating objects: 3, done.
Counting objects: 100% (3/3), done.
Delta compression using up to 10 threads
Compressing objects: 100% (2/2), done.
Writing objects: 100% (3/3), 100.03 MiB | 1.08 MiB/s, done.
Total 3 (delta 0), reused 0 (delta 0), pack-reused 0
remote: GitLab: You are attempting to check in one or more files which exceed the 100MiB limit:

- 257cc5642cb1a054f08cc83f2d943e56fd3ebe99 (123 MiB)
- 5716ca5987cbf97d6bb54920bea6adde242d87e6 (396 MiB)

Please refer to https://docs.gitlab.com/ee/user/free_user_limit.html for further information.
To https://gitlab.com/group/my-project.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to 'https://gitlab.com/group/my-project.git'
```

エラーには、ファイル名ではなく、ファイルの一意のIDがリストされます。一意のIDからファイル名を調べるには、次のコマンドを実行します:

```shell
tree -r | grep <id>
```

Gitは大きなテキストベース以外のデータをうまく処理するように設計されていないため、これらのファイルには[Git LFS](../topics/git/lfs/_index.md)を使用する必要があります。Git LFSは、Gitと連携して大きなファイルを追跡するように設計されています。
