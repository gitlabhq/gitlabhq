---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: "`gitプッシュ` でプロジェクトを作成"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

`git push`を使用して、ローカルプロジェクトリポジトリをGitLabに追加できます。リポジトリを追加すると、GitLabは選択したネームスペースにプロジェクトを作成します。

{{< alert type="note" >}}

`git push`を使用して、以前に使用されたパスを持つプロジェクトや、[名前が変更された](../../user/project/working_with_projects.md#rename-a-repository)プロジェクトを作成することはできません。以前に使用されたプロジェクトのパスには、リダイレクトが設定されています。新しいプロジェクトを作成する代わりに、リダイレクトによってプッシュ試行がリダイレクトされ、名前が変更されたプロジェクトの場所にリクエストがリダイレクトされます。以前に使用されたプロジェクトまたは名前が変更されたプロジェクトの新しいプロジェクトを作成するには、UIまたは[Projects API](../../api/projects.md#create-a-project)を使用します。

{{< /alert >}}

前提要件: 

<!--- To push with SSH, you must have [an SSH key](../ssh.md) that is
  [added to your GitLab account](../ssh.md#add-an-ssh-key-to-your-gitlab-account).
-->
- [ネームスペース](../../user/namespace/_index.md)に新しいプロジェクトを追加する権限が必要です。権限を確認するには、次の手順に従ってください。:

  1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
  1. 右上隅で、**新規プロジェクト**が表示されていることを確認します。

  必要な権限がない場合は、GitLab管理者にお問い合わせください。

`git push`でプロジェクトを作成するには、次の手順を実行します。:

1. 次のいずれかの方法で、ローカルリポジトリをGitLabにプッシュします。:

   - SSHを使用する場合：

      - プロジェクトが標準ポート22を使用している場合は、以下を実行します。:

        ```shell
        git push --set-upstream git@gitlab.example.com:namespace/myproject.git main
        ```

      - プロジェクトが非標準ポート番号を必要とする場合は、以下を実行します。:

        ```shell
        git push --set-upstream ssh://git@gitlab.example.com:00/namespace/myproject.git main
        ```

   - HTTPを使用する場合は、以下を実行します。:

     ```shell
     git push --set-upstream https://gitlab.example.com/namespace/myproject.git master
     ```

     次の値を置き換えてください。:

     - `gitlab.example.com`を、GitリポジトリをホストするマシンGoのドメイン名に置き換えます。
     - `namespace`を、[ネームスペース](../../user/namespace/_index.md)名に置き換えます。
     - `myproject`をプロジェクト名に置き換えます。
     - ポートを指定する場合は、`00`をプロジェクトに必要なポート番号に変更します。
     - オプション。既存のリポジトリのタグ付けをエクスポートするには、`--tags`フラグを`git push`コマンドに追加します。

1. オプション。リモートを設定します。:

   ```shell
   git remote add origin https://gitlab.example.com/namespace/myproject.git
   ```

`git push`操作が完了すると、GitLabは次のメッセージを表示します。:

```shell
remote: The private project namespace/myproject was created.
```

新しいプロジェクトを表示するには、`https://gitlab.example.com/namespace/myproject`にアクセスします。既定では、プロジェクトの表示レベルは**プライベート**に設定されていますが、[プロジェクトの表示レベルを変更](../../user/public_access.md#change-project-visibility)できます。

## 関連トピック {#related-topics}

- [空のプロジェクトを作成する](../../user/project/_index.md)
- [テンプレートからプロジェクトを作成](../../user/project/_index.md#create-a-project-from-a-built-in-template)
- [リポジトリをローカルマシンにクローンする](clone.md)。
