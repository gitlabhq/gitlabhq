---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループのAPIレート制限
description: ファイルに記録されます。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

> [!note]
> GitLab 18.0以降にアップグレードすると、このAPIの構成可能なレート制限は`0`に設定されます。管理者は必要に応じてレート制限を調整できます。影響を受けるレート制限に関する情報については、[プロジェクト、グループ、ユーザーAPIのレート制限に関する発表](https://about.gitlab.com/blog/rate-limitations-announced-for-projects-groups-and-users-apis/#rate-limitation-details)を参照してください。

## グループのAPIレート制限を設定する {#configure-groups-api-rate-limits}

{{< history >}}

- GitLab 17.1で`rate_limit_groups_and_projects_api`[フラグ](../../administration/feature_flags/_index.md)とともに、グループおよびプロジェクトAPIに対するレート制限が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152733)されました。デフォルトでは無効になっています。
- GitLab 18.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/461316)になりました。機能フラグ`rate_limit_groups_and_projects_api`は削除されました。
- GitLab 19.3で`namespace_create_rate_limit`[フラグ](../../administration/feature_flags/_index.md)とともに、グループの作成に対するレート制限が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/245318)されました。デフォルトでは無効になっています。

{{< /history >}}

以下のグループAPIエンドポイントへのリクエストに対して、各IPアドレスとユーザーのレート制限を設定します:

| 制限                                                           | デフォルト | 間隔 |
|-----------------------------------------------------------------|---------|----------|
| [`GET /groups`](../../api/groups.md#list-groups)                | 200     | 1分 |
| [`GET /groups/:id`](../../api/groups.md#retrieve-a-group)     | 400     | 1分 |
| [`GET /groups/:id/groups/shared`](../../api/groups.md#list-shared-groups) | 0     | 1分 |
| [`GET /groups/:id/invited_groups`](../../api/groups.md#list-shared-groups) | 60     | 1分 |
| [`GET /groups/:id/projects`](../../api/groups.md#list-projects) | 600     | 1分 |
| [`POST /groups/:id/archive`](../../api/groups.md#archive-a-group) | 60    | 1分 |
| [`POST /groups`](../../api/groups.md#create-a-group)            | 200     | 1日 |

前提条件: 

- 管理者アクセス権。

レート制限を変更するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **ネットワーク**を選択します。
1. **グループのAPIレート制限**を展開します。
1. レート制限の値を変更するか、無効にするにはレート制限を`0`に設定します。
1. **変更を保存**を選択します。

レート制限:

- 各認証済みユーザーに適用されます。リクエストが認証されていない場合、レート制限はIPアドレスに適用されます。
- レート制限を無効にするには0に設定できます。

レート制限を超過したリクエストは、`auth.log`ファイルにログが記録されます。

たとえば、`GET /groups/:id`に400の制限を設定した場合、1分あたり400を超えるレートのエンドポイントへのリクエストはブロックされます。エンドポイントへのアクセスは1分後に復元されます。

## グループおよびプロジェクトメンバーのリスト表示に関するレート制限 {#rate-limit-on-listing-group-and-project-members}

{{< history >}}

- GitLab 18.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/578527)されました。

{{< /history >}}

[すべてのグループメンバーをリスト表示するAPIエンドポイント](../../api/group_members.md#list-all-group-members-including-inherited-and-invited-members)にレート制限が設定されます。

`GET /projects/:id/members/all`と`GET /groups/:id/members/all`のAPIエンドポイントは、同じレート制限設定を共有します。プロジェクトエンドポイントにレート制限を設定した場合、そのレート制限はグループエンドポイントにも適用されます。

前提条件: 

- 管理者アクセス権。

両方のエンドポイントのこのレート制限を変更するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **ネットワーク**を選択します。
1. **プロジェクトのAPIレート制限**を展開します。
1. **ユーザーまたはIPアドレスごとの、1分あたりの`GET /projects/:id/members/all` APIへの最大リクエスト数**テキストボックスに値を入力します。
1. **変更を保存**を選択します。

レート制限:

- デフォルトは毎分200リクエストです。
- 各認証済みユーザーに適用されます。リクエストが認証されていない場合、レート制限はIPアドレスに適用されます。
- プロジェクトAPIレート制限設定を通じて構成されます。詳細については、[プロジェクトメンバーのリスト表示に関するレート制限を設定する](projects.md#configure-rate-limits-on-listing-project-members)を参照してください。
- 両方のエンドポイントのレート制限を無効にするには、`0`に設定できます。

レート制限を超過したリクエストは、`auth.log`ファイルにログが記録されます。

例えば、毎分200リクエストを超えるAPIエンドポイントへのリクエストはブロックされます。エンドポイントへのアクセスは1分後に再開されます。

## グループのアーカイブおよびアーカイブ解除に関するレート制限を設定する {#configure-rate-limits-on-group-archiving-and-unarchiving}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.0で`archive_group`[機能フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/481969)されました。デフォルトでは無効になっています。
- GitLab 18.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/526771)になりました。機能フラグ`archive_group`は削除されました。

{{< /history >}}

以下のグループアーカイブエンドポイントへのリクエストにレート制限を設定します:

```plaintext
POST /groups/:id/archive
POST /groups/:id/unarchive
```

前提条件: 

- 管理者アクセス権。

レート制限を変更するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **ネットワーク**を選択します。
1. **グループのAPIレート制限**を展開します。
1. **ユーザーまたはIPアドレスごとの、1分あたりの`POST /groups/:id/archive`および`POST /groups/:id/unarchive` APIへの最大リクエスト数**テキストボックスに値を入力します。
1. **変更を保存**を選択します。

レート制限:

- デフォルトは毎分60リクエストです。
- 各認証済みユーザーに適用されます。リクエストが認証されていない場合、レート制限はIPアドレスに適用されます。
- 両方のエンドポイントのレート制限を無効にするには、`0`に設定できます。

レート制限を超過したリクエストは、`auth.log`ファイルにログが記録されます。

例えば、60の制限を設定した場合、1分あたり60リクエストを超えるAPIエンドポイントへのリクエストはブロックされます。エンドポイントへのアクセスは1分後に再開されます。

グループのアーカイブエンドポイントの詳細については、[グループのアーカイブ](../../api/groups.md#archive-a-group)を参照してください。

## グループメンバーの削除に関するレート制限を設定する {#configure-rate-limits-on-deleting-group-members}

[メンバー削除エンドポイント](../../api/group_members.md#remove-a-group-member)へのリクエストに対するグループおよびユーザーごとのレート制限を設定します。

前提条件: 

- 管理者アクセス権。

レート制限を変更するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **ネットワーク**を選択します。
1. **メンバーAPIレート制限**を展開します。
1. **グループまたはプロジェクトあたりの一分あたりの最大リクエスト数**テキストボックスに値を入力します。
1. **変更を保存**を選択します。

レート制限:

- デフォルトは毎分60リクエストです。
- 各グループとユーザーに適用されます。
- レート制限を無効にするには、`0`に設定できます。

レート制限を超過したリクエストは、`auth.log`ファイルにログが記録されます。

例えば、60の制限を設定した場合、毎分60リクエストを超えるAPIエンドポイントへのリクエストはブロックされます。エンドポイントへのアクセスは1分後に復元されます。
