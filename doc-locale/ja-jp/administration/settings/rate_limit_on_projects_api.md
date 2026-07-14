---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトAPIのレート制限
description: プロジェクトAPIのエンドポイントにレート制限を設定します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

> [!note]
> GitLab 18.0以降にアップグレードすると、このAPIの設定可能なレート制限は`0`に設定されます。管理者は必要に応じてレート制限を調整できます。影響を受けるレート制限については、[Projects、Groups、およびUsers APIに関するレート制限の発表](https://about.gitlab.com/blog/rate-limitations-announced-for-projects-groups-and-users-apis/#rate-limitation-details)を参照してください。

## プロジェクトAPIのレート制限を設定する {#configure-projects-api-rate-limits}

{{< history >}}

- GitLab 16.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120445)になりました。機能フラグ`rate_limit_for_unauthenticated_projects_api_access`は削除されました。
- グループおよびプロジェクトAPIのレート制限は、GitLab 17.1で`rate_limit_groups_and_projects_api`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/421909)されました。デフォルトでは無効になっています。
- GitLab 18.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/461316)になりました。機能フラグ`rate_limit_groups_and_projects_api`は削除されました。

{{< /history >}}

以下のプロジェクトAPIエンドポイントへのリクエストについて、各IPアドレスとユーザーのレート制限を設定します:

| 制限                                                                                                       | デフォルト | 間隔 |
|-------------------------------------------------------------------------------------------------------------|---------|----------|
| [`GET /projects`](../../api/projects.md#list-all-projects) (未認証のリクエスト)                       | 400     | 10分 |
| [`GET /projects`](../../api/projects.md#list-all-projects) (認証済みリクエスト)                         | 2000    | 10分 |
| [`GET /projects/:id`](../../api/projects.md#retrieve-a-project)                                             | 400     | 1分 |
| [`GET /users/:user_id/projects`](../../api/projects.md#list-all-personal-projects-for-a-user)               | 300     | 1分 |
| [`GET /users/:user_id/contributed_projects`](../../api/projects.md#list-all-projects-contributions-for-a-user) | 100     | 1分 |
| [`GET /users/:user_id/starred_projects`](../../api/project_starring.md#list-projects-starred-by-a-user)     | 100     | 1分 |

前提条件: 

- 管理者アクセス権。

レート制限を変更するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **ネットワーク**を選択します。
1. **プロジェクトのAPIレート制限**を展開する。
1. レート制限の値を変更するか、またはレート制限を`0`に設定して無効にします。
1. **変更を保存**を選択します。

レート制限:

- 各認証済みユーザーに適用されます。リクエストが認証されていない場合、レート制限はIPアドレスに適用されます。

レート制限を超えるリクエストは、`auth.log`ファイルにログが記録されます。

たとえば、`GET /projects/:id`に400の制限を設定した場合、1分あたり400リクエストのレートを超えるAPIエンドポイントへのリクエストはブロックされます。1分後にエンドポイントへのアクセスが復元されます。

プロジェクトAPIエンドポイントの詳細については、[projects API](../../api/projects.md#list-all-projects)を参照してください。

## プロジェクトメンバーの削除に関するレート制限を設定する {#configure-rate-limits-on-deleting-project-members}

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/420321)されました。

{{< /history >}}

[メンバー削除エンドポイント](../../api/project_members.md#remove-a-direct-member-of-a-project)へのリクエストについて、各プロジェクトとユーザーのレート制限を設定します。

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
- 各プロジェクトとユーザーに適用されます。
- レート制限を無効にするには`0`に設定できます。

レート制限を超えるリクエストは、`auth.log`ファイルにログが記録されます。

例えば、60の制限を設定した場合、毎分60リクエストを超えるリクエストを送信するAPIエンドポイントはブロックされます。1分後にエンドポイントへのアクセスが再開されます。

## プロジェクトメンバーのリスト表示に関するレート制限を設定する {#configure-rate-limits-on-listing-project-members}

{{< history >}}

- GitLab 18.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/578527)されました。

{{< /history >}}

[プロジェクトメンバーリストエンドポイント](../../api/project_members.md#list-all-members-of-a-project)へのリクエストのレート制限を設定します。

`GET /projects/:id/members/all`と`GET /groups/:id/members/all`のAPIエンドポイントは、同じレート制限設定を共有します。プロジェクトエンドポイントにレート制限を設定すると、そのレート制限はグループエンドポイントにも適用されます。

前提条件: 

- 管理者アクセス権。

レート制限を変更するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **ネットワーク**を選択します。
1. **プロジェクトのAPIレート制限**を展開する。
1. **Maximum requests to the `GET /projects/:id/members/all` API per minute per user or IP address**テキストボックスに値を入力します。
1. **変更を保存**を選択します。

レート制限:

- 毎分200リクエストがデフォルトです。
- 各プロジェクトとユーザーに適用されます。
- レート制限を無効にするには、`0`に設定できます。

レート制限を超えるリクエストは、`auth.log`ファイルにログが記録されます。

たとえば、200の制限を設定した場合、1分あたり200リクエストのレートを超えるAPIエンドポイントへのリクエストはブロックされます。1分後にエンドポイントへのアクセスが再開されます。
