---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Self-ManagedのGit SSH操作のレート制限を設定します。
title: Git SSH操作のレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、ユーザーアカウントとプロジェクトごとに、SSHを使用するGit操作にレート制限を適用します。ユーザーがレート制限を超えると、GitLabはそのユーザーからのプロジェクトへの接続リクエストを拒否します。

レート制限は、Gitコマンド（[配管（Plumbing）](https://git-scm.com/book/en/v2/Git-Internals-Plumbing-and-Porcelain)）レベルで適用されます。各コマンドには、1分あたり600のレート制限があります。例: 

- `git push`には、1分あたり600のレート制限があります。
- `git pull`には、独自の1分あたり600のレート制限があります。

`git-upload-pack`、`git pull`、および`git clone`のコマンドは、コマンドを共有するため、レート制限を共有します。

## GitLab Shell操作制限を設定します {#configure-gitlab-shell-operation-limit}

{{< history >}}

- GitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123761)されました。

{{< /history >}}

`Git operations using SSH`はデフォルトで有効になっています。デフォルトは、ユーザーあたり1分あたり600です。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **Git SSH操作レート制限**を展開します。
1. **1分あたりのgit操作の最大数**の値を入力します。
   - レート制限を無効にするには、`0`に設定します。
1. **変更を保存**を選択します。
