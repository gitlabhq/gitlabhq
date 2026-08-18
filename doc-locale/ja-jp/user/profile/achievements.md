---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: アチーブメント
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.10で`achievements`[機能フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113156)されました。デフォルトでは無効になっています。
- GitLab 19.2の[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効化](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200774)されました。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

アチーブメントは、GitLabでのユーザーのアクティビティを報酬として与える方法です。ネームスペースのメンテナーまたはオーナーは、特定のコントリビュートに対してカスタムのアチーブメントを作成できます。これらのアチーブメントをユーザーに授与したり、定義された基準に基づいて失効することができます。

ユーザーとして、プロファイル上の異なるプロジェクトやグループへのコントリビュートを強調するためにアチーブメントを収集できます。アチーブメントは、名前、説明、およびアバターで構成されます。

![ユーザープロファイルページのアチーブメント](img/user_profile_achievements_v15_11.png)

アチーブメントはユーザーが所有しているものと見なされます。アチーブメントを作成したネームスペースの表示レベル設定に関係なく表示されます。

計画されている作業の詳細については、[エピック9429](https://gitlab.com/groups/gitlab-org/-/epics/9429)を参照してください。エピックにコメントを残して、ユースケースについて教えてください。

## アチーブメントの種類 {#types-of-achievement}

プログラム的には、アチーブメントを作成、授与、失効する、または削除する方法は1つしかありません。

実際には、授与されるアチーブメントを次のように区別できます:

- 一度きりで取り消し不能。たとえば、「最初のコントリビュートがマージされました」アチーブメントなど。
- 一度きりで失効することができます。たとえば、「コアチームメンバー」アチーブメントなど。
- 複数回。たとえば、「今月のコントリビューター」アチーブメントなど。

## グループアチーブメントを表示 {#view-group-achievements}

グループで利用可能および授与されたすべてのアチーブメントを表示するには:

- `https://gitlab.com/groups/<group-path>/-/achievements`に移動します。

このページには、アチーブメントのリストと、アチーブメントを授与されたメンバーが表示されます。

## ユーザーのアチーブメントを表示 {#view-a-users-achievements}

ユーザーのプロファイルページでユーザーのアチーブメントを表示できます。

前提条件: 

- ユーザープロファイルは公開されている必要があります。

ユーザーのアチーブメントを表示するには:

1. ユーザーのプロファイルページに移動します。
1. ユーザーのアバターの下に、アチーブメントが表示されます。
1. アチーブメントの詳細を表示するには、それにカーソルを合わせる。以下の情報が表示されます:

   - アチーブメントの名前
   - アチーブメントの説明
   - アチーブメントがユーザーに授与された日付
   - ユーザーがネームスペースのメンバーであるか、またはネームスペースが公開されている場合に、アチーブメントを授与したネームスペース

ユーザーのアチーブメントのリストを取得するには、[`user` GraphQL型](../../api/graphql/reference/_index.md#user)をクエリする。

フィールド`User.userAchievements`はオプションのパラメータ`includeHidden`を受け入れます。`true`に設定すると、応答にはプロファイルから隠されたアチーブメントが含まれます。非表示のアチーブメントは、次のケースでのみ含まれます:

- 要求しているユーザーが、要求されたユーザーと同じである。
- 要求しているユーザーが、アチーブメントが属するグループでメンテナーまたはオーナーロールを持っている。

```graphql
query {
  user(username: "<username>") {
    userAchievements(includeHidden: true) {
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

特定のコントリビュートに対して授与するためのカスタムアチーブメントを作成できます。

前提条件: 

- ネームスペースのメンテナーまたはオーナーロールを持っている必要があります。

アチーブメントを作成するには:

- UIの場合:
  1. [アチーブメントページ](#view-group-achievements)で、**新しいアチーブメント**を選択します。
  1. アチーブメントの名前を入力します。
  1. オプション。任意。説明を入力し、アチーブメントのアバターをアップロードします。
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

  アバターファイルを提供するには、`curl`を使用してミューテーションを呼び出す:

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

いつでもアチーブメントの名前、説明、およびアバターを変更できます。

前提条件: 

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

{{< history >}}

- GitLab 19.0で、受信者の承認が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227918)されました。

{{< /history >}}

ユーザーのコントリビュートを認識するために、アチーブメントを授与できます。ユーザーに授与した後、アチーブメントを受け入れるためのリンクを含むメール通知を受け取ります。アチーブメントは、ユーザーが受け入れるまでプロファイルには表示されません。

承認リンクは30日間有効です。その期間を過ぎた後、アチーブメントを受け入れるには、[`userAchievementsUpdate` GraphQLミューテーション](#change-visibility-of-specific-achievements)を呼び出す。

前提条件: 

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

## アチーブメントを失効する {#revoke-an-achievement}

ユーザーが授与基準を満たさなくなったと判断した場合、ユーザーのアチーブメントを失効することができます。

前提条件: 

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

誤ってユーザーにアチーブメントを授与した場合、それを削除できます。

前提条件: 

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

アチーブメントが不要になったと判断した場合、それを削除できます。これにより、アチーブメントの関連するすべての授与および失効されたインスタンスが削除されます。

前提条件: 

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

## アチーブメントを非表示にする {#hide-achievements}

プロファイルにアチーブメントを表示したくない場合は、オプトアウトできます。これを行うには:

1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
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

アチーブメントの1つを再度表示するには、`showOnProfile`引数に値`true`を指定して同じミューテーションを呼び出す。

## アチーブメントを並べ替える {#reorder-achievements}

デフォルトでは、プロファイルのアチーブメントは授与された日付の昇順で表示されます。

アチーブメントの順序を変更するには、優先順位付けされたすべてのアチーブメントの順序付きリストを指定して、[`userAchievementPrioritiesUpdate` GraphQLミューテーション](../../api/graphql/reference/_index.md#mutationuserachievementprioritiesupdate)を呼び出す。

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
