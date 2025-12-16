---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アチーブメント
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 15.10で`achievements`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113156)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

GitLab Self-Managedでは、デフォルトでこの機能は使用できません。管理者が`achievements`という名前の[機能フラグを有効にする](../../administration/feature_flags/_index.md)と、この機能を使用できるようになります。

{{< /alert >}}

GitLabのアクティビティーに対してユーザーに報酬を与える方法がアチーブメントです。ネームスペースのメンテナーまたはオーナーとして、特定のコントリビューションに対してカスタムアチーブメントを作成できます。定義された基準に基づいて、これらのアチーブメントをユーザーに授与したり、失効させたりすることができます。

ユーザーは、自分のプロフィールのさまざまなプロジェクトまたはグループへのコントリビューションを強調するために、アチーブメントを収集できます。アチーブメントは、名前、説明、およびアバターで構成されます。

![ユーザープロファイルページ上のアチーブメント](img/user_profile_achievements_v15_11.png)

アチーブメントは、ユーザーが所有するものと見なされます。これらは、アチーブメントを作成したネームスペースの表示レベル設定に関係なく表示されます。

この機能は、実験です。計画された作業の詳細については、[エピック9429](https://gitlab.com/groups/gitlab-org/-/epics/9429)を参照してください。エピックにコメントを残して、ユースケースをお知らせください。

## アチーブメントの種類 {#types-of-achievement}

プログラムでアチーブメントを作成、授与、失効、または削除する方法は1つしかありません。

実際には、授与されるアチーブメントを区別できます:

- 1回限りで取り消し不能。たとえば、「最初のコントリビューションがマージされました」アチーブメント。
- 1回限りで取り消し可能。たとえば、「コアチームメンバー」アチーブメント。
- 複数回。たとえば、「今月のコントリビューター」アチーブメント。

## グループアチーブメントを表示 {#view-group-achievements}

グループで利用可能で授与されたすべてのアチーブメントを表示するには:

- `https://gitlab.com/groups/<group-path>/-/achievements`に移動します。

このページには、アチーブメントのリストと、アチーブメントを授与されたメンバーが表示されます。

## ユーザーのアチーブメントを表示 {#view-a-users-achievements}

ユーザーのプロファイルページで、ユーザーのアチーブメントを表示できます。

前提要件: 

- ユーザープロファイルは公開されている必要があります。

ユーザーのアチーブメントを表示するには:

1. ユーザーのプロフィールページに移動します。
1. ユーザーのアバターの下に、そのアチーブメントが表示されます。
1. アチーブメントの詳細を表示するには、カーソルを合わせる。次の情報が表示されます:

   - アチーブメントの名前
   - アチーブメントの説明
   - アチーブメントがユーザーに授与された日付
   - ユーザーがネームスペースのメンバーであるか、ネームスペースが公開されている場合にアチーブメントを授与したネームスペース

ユーザーのアチーブメントのリストを取得するには、[`user` GraphQLタイプ](../../api/graphql/reference/_index.md#user)をクエリします。

```graphql
query {
  user(username: "<username>") {
    userAchievements {
      nodes {
        achievement {
          name
          description
          avatarUrl
          namespace {
            fullPath
            name
          }
        }
      }
    }
  }
}
```

## アチーブメントを作成 {#create-an-achievement}

特定のコントリビューションに対して授与するカスタムアチーブメントを作成できます。

前提要件: 

- ネームスペースのメンテナーまたはオーナーロールを持っている必要があります。

アチーブメントを作成するには:

- UIの場合:
  1. [アチーブメントページ](#view-group-achievements)で、**新しいアチーブメント**を選択します。
  1. アチーブメントの名前を入力します。
  1. オプション。アチーブメントの説明を入力し、アバターをアップロードします。
  1. **変更を保存**を選択します。

- GraphQL APIを使用して、[`achievementsCreate` GraphQLミューテーション](../../api/graphql/reference/_index.md#mutationachievementscreate)を呼び出す:

  ```graphql
  mutation achievementsCreate($file: Upload!) {
    achievementsCreate(
      input: {
        namespaceId: "gid://gitlab/Namespace/<namespace id>",
        name: "<name>",
        description: "<description>",
        avatar: $file}
    ) {
      errors
      achievement {
        id
        name
        description
        avatarUrl
      }
    }
  }
  ```

  アバターファイルを指定するには、`curl`を使用してミューテーションを呼び出す:

  ```shell
  curl "https://gitlab.com/api/graphql" \
    -H "Authorization: Bearer <your-pat-token>" \
    -H "Content-Type: multipart/form-data" \
    -F operations='{ "query": "mutation ($file: Upload!) { achievementsCreate(input: { namespaceId: \"gid://gitlab/Namespace/<namespace-id>\", name: \"<name>\", description: \"<description>\", avatar: $file }) { achievement { id name description avatarUrl } } }", "variables": { "file": null } }' \
    -F map='{ "0": ["variables.file"] }' \
    -F 0='@/path/to/your/file.jpg'
  ```

  成功すると、応答はアチーブメントIDを返します:

  ```shell
  {"data":{"achievementsCreate":{"achievement":{"id":"gid://gitlab/Achievements::Achievement/1","name":"<name>","description":"<description>","avatarUrl":"https://gitlab.com/uploads/-/system/achievements/achievement/avatar/1/file.jpg"}}}}
  ```

## アチーブメントを更新 {#update-an-achievement}

アチーブメントの名前、説明、およびアバターはいつでも変更できます。

前提要件: 

- ネームスペースのメンテナーまたはオーナーロールを持っている必要があります。

アチーブメントを更新するには、[`achievementsUpdate` GraphQLミューテーション](../../api/graphql/reference/_index.md#mutationachievementsupdate)を呼び出す。

```graphql
mutation achievementsUpdate($file: Upload!) {
  achievementsUpdate(
    input: {
      achievementId: "gid://gitlab/Achievements::Achievement/<achievement id>",
      name: "<new name>",
      description: "<new description>",
      avatar: $file}
  ) {
    errors
    achievement {
      id
      name
      description
      avatarUrl
    }
  }
}
```

## アチーブメントを授与 {#award-an-achievement}

ユーザーのコントリビューションを認識するために、アチーブメントをユーザーに授与できます。ユーザーがアチーブメントを授与されると、メール通知が届きます。

前提要件: 

- ネームスペースのメンテナーまたはオーナーロールを持っている必要があります。

ユーザーにアチーブメントを授与するには、[`achievementsAward` GraphQLミューテーション](../../api/graphql/reference/_index.md#mutationachievementsaward)を呼び出す。

```graphql
mutation {
  achievementsAward(input: {
    achievementId: "gid://gitlab/Achievements::Achievement/<achievement id>",
    userId: "gid://gitlab/User/<user id>" }) {
    userAchievement {
      id
      achievement {
        id
        name
      }
      user {
        id
        username
      }
    }
    errors
  }
}
```

## アチーブメントを失効 {#revoke-an-achievement}

ユーザーが授与基準を満たさなくなったと判断した場合は、ユーザーのアチーブメントを失効できます。

前提要件: 

- ネームスペースのメンテナーまたはオーナーロールを持っている必要があります。

アチーブメントを失効するには、[`achievementsRevoke` GraphQLミューテーション](../../api/graphql/reference/_index.md#mutationachievementsrevoke)を呼び出す。

```graphql
mutation {
  achievementsRevoke(input: {
    userAchievementId: "gid://gitlab/Achievements::UserAchievement/<user achievement id>" }) {
    userAchievement {
      id
      achievement {
        id
        name
      }
      user {
        id
        username
      }
      revokedAt
    }
    errors
  }
}
```

## 授与されたアチーブメントを削除 {#delete-an-awarded-achievement}

誤ってアチーブメントをユーザーに授与した場合は、削除できます。

前提要件: 

- ネームスペースのオーナーロールを持っている必要があります。

授与されたアチーブメントを削除するには、[`userAchievementsDelete` GraphQLミューテーション](../../api/graphql/reference/_index.md#mutationuserachievementsdelete)を呼び出す。

```graphql
mutation {
  userAchievementsDelete(input: {
    userAchievementId: "gid://gitlab/Achievements::UserAchievement/<user achievement id>" }) {
    userAchievement {
      id
      achievement {
        id
        name
      }
      user {
        id
        username
      }
    }
    errors
  }
}
```

## アチーブメントを削除 {#delete-an-achievement}

アチーブメントが不要になった場合は、削除できます。これにより、アチーブメントの関連するすべての授与済みインスタンスと失効済みインスタンスが削除されます。

前提要件: 

- ネームスペースのメンテナーまたはオーナーロールを持っている必要があります。

アチーブメントを削除するには、[`achievementsDelete` GraphQLミューテーション](../../api/graphql/reference/_index.md#mutationachievementsdelete)を呼び出す。

```graphql
mutation {
  achievementsDelete(input: {
    achievementId: "gid://gitlab/Achievements::Achievement/<achievement id>" }) {
    achievement {
      id
      name
    }
    errors
  }
}
```

## アチーブメントを非表示 {#hide-achievements}

プロファイルにアチーブメントを表示したくない場合は、オプトアウトできます。これを行うには、次の手順を実行します:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. **主要設定**セクションで、**プロファイルにアチーブメントを表示する**チェックボックスをオフにします。
1. **プロファイル設定を更新**を選択します。

## 特定のアチーブメントの表示レベルを変更 {#change-visibility-of-specific-achievements}

{{< history >}}

- GitLab 17.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161225)されました。

{{< /history >}}

プロファイルにすべてのアチーブメントを表示したくない場合は、特定のアチーブメントの表示レベルを変更できます。

アチーブメントの1つを非表示にするには、[`userAchievementsUpdate` GraphQLミューテーション](../../api/graphql/reference/_index.md#mutationuserachievementsupdate)を呼び出す。

```graphql
mutation {
  userAchievementsUpdate(input: {
    userAchievementId: "gid://gitlab/Achievements::UserAchievement/<user achievement id>"
    showOnProfile: false
  }) {
    userAchievement {
      id
      showOnProfile
    }
    errors
  }
}
```

アチーブメントを再度表示するには、`showOnProfile`引数の値`true`を指定して同じミューテーションを呼び出す。

## アチーブメントの順序を変更 {#reorder-achievements}

デフォルトでは、プロファイルのアチーブメントは、授与された日付の昇順で表示されます。

アチーブメントの順序を変更するには、優先順位が付けられたすべてのアチーブメントの順序付きリストを使用して、[`userAchievementPrioritiesUpdate` GraphQLミューテーション](../../api/graphql/reference/_index.md#mutationuserachievementprioritiesupdate)を呼び出す。

```graphql
mutation {
  userAchievementPrioritiesUpdate(input: {
    userAchievementIds: ["gid://gitlab/Achievements::UserAchievement/<first user achievement id>", "gid://gitlab/Achievements::UserAchievement/<second user achievement id>"],
    }) {
    userAchievements {
      id
      priority
    }
    errors
  }
}
```
