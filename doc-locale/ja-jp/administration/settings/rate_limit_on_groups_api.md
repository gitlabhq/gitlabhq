---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループAPIのレート制限
description: グループAPIのエンドポイントにレート制限を設定します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

> [!note]
> GitLab 18.0以降にアップグレードすると、このAPIの設定可能なレート制限は`0`に設定されます。管理者は必要に応じてレート制限を調整できます。影響を受けるレート制限については、[Projects、Groups、およびUsers APIに関するレート制限の発表](https://about.gitlab.com/blog/rate-limitations-announced-for-projects-groups-and-users-apis/#rate-limitation-details)を参照してください。

## グループAPIのレート制限を設定する {#configure-groups-api-rate-limits}

{{< history >}}

- グループおよびプロジェクトAPIのレート制限は、GitLab 17.1で`rate_limit_groups_and_projects_api`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152733)されました。デフォルトでは無効になっています。
- GitLab 18.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/461316)になりました。機能フラグ`rate_limit_groups_and_projects_api`は削除されました。

{{< /history >}}

次のグループAPIエンドポイントへのリクエストに対して、各IPアドレスとユーザーごとのレート制限を設定します:

| 制限                                                           | デフォルト | 間隔 |
|-----------------------------------------------------------------|---------|----------|
| [`GET /groups`](../../api/groups.md#list-groups)                | 200     | 1分 |
| [`GET /groups/:id`](../../api/groups.md#retrieve-a-group)     | 400     | 1分 |
| [`GET /groups/:id/groups/shared`](../../api/groups.md#list-shared-groups) | 0     | 1分 |
| [`GET /groups/:id/invited_groups`](../../api/groups.md#list-shared-groups) | 60     | 1分 |
| [`GET /groups/:id/projects`](../../api/groups.md#list-projects) | 600     | 1分 |
| [`POST /groups/:id/archive`](../../api/groups.md#archive-a-group) | 60    | 1分 |

前提条件: 

- 管理者アクセス権。

レート制限を変更するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **ネットワーク**を選択します。
1. **グループのAPIレート制限**を展開する。
1. いずれかのレート制限の値を変更するか、レート制限を`0`に設定して無効にします。
1. **変更を保存**を選択します。

レート制限:

- 各認証済みユーザーに適用されます。リクエストが認証されていない場合、レート制限はIPアドレスに適用されます。
- レート制限を無効にするには0に設定できます。

レート制限を超えるリクエストは、`auth.log`ファイルにログが記録されます。

例えば、`GET /groups/:id`に対して400の制限を設定した場合、毎分400を超えるリクエストを送信するAPIエンドポイントへのリクエストはブロックされます。1分後にエンドポイントへのアクセスが復元されます。

## グループメンバーのリスト表示におけるレート制限 {#rate-limit-on-listing-group-members}

{{< history >}}

- GitLab 18.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/578527)されました。

{{< /history >}}

[すべてのグループメンバーをリストするAPIエンドポイント](../../api/group_members.md#list-all-group-members-including-inherited-and-invited-members)にレート制限が設定されています。

`GET /projects/:id/members/all`と`GET /groups/:id/members/all`のAPIエンドポイントは、同じレート制限設定を共有します。プロジェクトエンドポイントにレート制限を設定すると、そのレート制限はグループエンドポイントにも適用されます。

前提条件: 

- 管理者アクセス権。

両方のエンドポイントに対してこのレート制限を変更するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **ネットワーク**を選択します。
1. **プロジェクトのAPIレート制限**を展開する。
1. **Maximum requests to the `GET /projects/:id/members/all` API per minute per user or IP address**テキストボックスに値を入力します。
1. **変更を保存**を選択します。

レート制限:

- 毎分200リクエストがデフォルトです。
- 各グループとユーザーに適用されます。
- プロジェクトのAPIレート制限設定を通じて設定されます。詳細については、[プロジェクトメンバーをリストするレート制限を設定する](rate_limit_on_projects_api.md#configure-rate-limits-on-listing-project-members)を参照してください。
- 両方のエンドポイントに対してレート制限を無効にするには`0`に設定できます。

レート制限を超えるリクエストは、`auth.log`ファイルにログが記録されます。

例えば、毎分200リクエストを超える速度でリクエストを送信するAPIエンドポイントへのリクエストはブロックされます。1分後にエンドポイントへのアクセスが再開されます。

## グループのアーカイブとアーカイブ解除におけるレート制限を設定する {#configure-rate-limits-on-group-archiving-and-unarchiving}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.0で`archive_group`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/481969)されました。デフォルトでは無効になっています。
- GitLab 18.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/526771)になりました。機能フラグ`archive_group`は削除されました。

{{< /history >}}

次のグループアーカイブエンドポイントへのリクエストに対するレート制限を設定します:

```plaintext
POST /groups/:id/archive
POST /groups/:id/unarchive
```

前提条件: 

- 管理者アクセス権。

レート制限を変更するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **ネットワーク**を選択します。
1. **グループのAPIレート制限**を展開する。
1. **Maximum requests to the `POST /groups/:id/archive` and `POST /groups/:id/unarchive` API per minute per user or IP address**テキストボックスに値を入力します。
1. **変更を保存**を選択します。

レート制限:

- 毎分60リクエストがデフォルトです。
- 各認証済みユーザーに適用されます。リクエストが認証されていない場合、レート制限はIPアドレスに適用されます。
- 両方のエンドポイントに対してレート制限を無効にするには`0`に設定できます。

レート制限を超えるリクエストは、`auth.log`ファイルにログが記録されます。

例えば、60の制限を設定した場合、毎分60リクエストを超えるリクエストを送信するAPIエンドポイントはブロックされます。1分後にエンドポイントへのアクセスが再開されます。

グループアーカイブエンドポイントの詳細については、[グループをアーカイブする](../../api/groups.md#archive-a-group)を参照してください。

## グループメンバーの削除におけるレート制限を設定する {#configure-rate-limits-on-deleting-group-members}

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/420321)されました。

{{< /history >}}

[メンバー削除エンドポイント](../../api/group_members.md#remove-a-group-member)へのリクエストに対して、各グループとユーザーのレート制限を設定します。

前提条件: 

- 管理者アクセス権。

レート制限を変更するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **ネットワーク**を選択します。
1. **Members API rate limit**を展開する。
1. **グループまたはプロジェクトあたりの一分あたりの最大リクエスト数**テキストボックスに値を入力します。
1. **変更を保存**を選択します。

レート制限:

- 毎分60リクエストがデフォルトです。
- 各グループとユーザーに適用されます。
- レート制限を無効にするには`0`に設定できます。

レート制限を超えるリクエストは、`auth.log`ファイルにログが記録されます。

例えば、60の制限を設定した場合、毎分60リクエストを超えるリクエストを送信するAPIエンドポイントはブロックされます。1分後にエンドポイントへのアクセスが復元されます。
