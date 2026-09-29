---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトのAPIレート制限
description: プロジェクトAPIエンドポイントにレート制限を設定します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

> [!note]
> GitLab 18.0以降にアップグレードすると、このAPIの構成可能なレート制限は`0`に設定されます。管理者は必要に応じてレート制限を調整できます。影響を受けるレート制限に関する情報については、[プロジェクト、グループ、ユーザーAPIのレート制限に関する発表](https://about.gitlab.com/blog/rate-limitations-announced-for-projects-groups-and-users-apis/#rate-limitation-details)を参照してください。

## プロジェクトのAPIレート制限を設定する {#configure-projects-api-rate-limits}

{{< history >}}

- GitLab 17.1で`rate_limit_groups_and_projects_api`[フラグ](../../administration/feature_flags/_index.md)とともにグループおよびプロジェクトAPIに対するレート制限が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/421909)されました。デフォルトでは無効になっています。
- GitLab 18.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/461316)になりました。機能フラグ`rate_limit_groups_and_projects_api`は削除されました。
- GitLab 19.3で`namespace_create_rate_limit`[フラグ](../../administration/feature_flags/_index.md)とともに、プロジェクトの作成に対するレート制限が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/245318)されました。デフォルトでは無効になっています。

{{< /history >}}

以下のプロジェクトAPIエンドポイントへのリクエストに対し、各IPアドレスとユーザーのレート制限を設定します:

| 制限                                                                                                       | デフォルト | 間隔 |
|-------------------------------------------------------------------------------------------------------------|---------|----------|
| [`GET /projects`](../../api/projects.md#list-all-projects)（未認証のリクエスト）                       | 400     | 10分 |
| [`GET /projects`](../../api/projects.md#list-all-projects)（認証済みリクエスト）                         | 2000    | 10分 |
| [`GET /projects/:id`](../../api/projects.md#retrieve-a-project)                                             | 400     | 1分 |
| [`GET /users/:user_id/projects`](../../api/projects.md#list-all-personal-projects-for-a-user)               | 300     | 1分 |
| [`GET /users/:user_id/contributed_projects`](../../api/projects.md#list-all-projects-contributions-for-a-user) | 100     | 1分 |
| [`GET /users/:user_id/starred_projects`](../../api/project_starring.md#list-projects-starred-by-a-user)     | 100     | 1分 |
| [`POST /projects`](../../api/projects.md#create-a-project)                                                  | 200     | 1日 |

前提条件: 

- 管理者アクセス権。

レート制限を変更するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **ネットワーク**を選択します。
1. **プロジェクトのAPIレート制限**を展開します。
1. レート制限の値を変更するか、`0`に設定してレート制限を無効にします。
1. **変更を保存**を選択します。

レート制限:

- 各認証済みユーザーに適用されます。リクエストが認証されていない場合、レート制限はIPアドレスに適用されます。

レート制限を超過したリクエストは、`auth.log`ファイルにログが記録されます。

例えば、`GET /projects/:id`に対して400の制限を設定した場合、1分あたり400リクエストを超えるAPIエンドポイントへのリクエストはブロックされます。エンドポイントへのアクセスは1分後に復元されます。

プロジェクトAPIエンドポイントの詳細については、[プロジェクトAPI](../../api/projects.md#list-all-projects)を参照してください。

## プロジェクトメンバーの削除に関するレート制限を設定する {#configure-rate-limits-on-deleting-project-members}

[メンバー削除エンドポイント](../../api/project_members.md#remove-a-direct-member-of-a-project)へのリクエストについて、各プロジェクトとユーザーのレート制限を設定します。

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
- 各プロジェクトとユーザーに適用されます。
- レート制限を無効にするには、`0`に設定できます。

レート制限を超過したリクエストは、`auth.log`ファイルにログが記録されます。

例えば、60の制限を設定した場合、1分あたり60リクエストを超えるAPIエンドポイントへのリクエストはブロックされます。エンドポイントへのアクセスは1分後に再開されます。

## プロジェクトメンバーのリスト表示に関するレート制限を設定する {#configure-rate-limits-on-listing-project-members}

{{< history >}}

- GitLab 18.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/578527)されました。

{{< /history >}}

[プロジェクトメンバーリストエンドポイント](../../api/project_members.md#list-all-members-of-a-project)へのリクエストのレート制限を設定します。

`GET /projects/:id/members/all`と`GET /groups/:id/members/all`のAPIエンドポイントは、同じレート制限設定を共有します。プロジェクトエンドポイントにレート制限を設定した場合、そのレート制限はグループエンドポイントにも適用されます。

前提条件: 

- 管理者アクセス権。

レート制限を変更するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **ネットワーク**を選択します。
1. **プロジェクトのAPIレート制限**を展開します。
1. **ユーザーまたはIPアドレスごとの、1分あたりの`GET /projects/:id/members/all` APIへの最大リクエスト数**テキストボックスに値を入力します。
1. **変更を保存**を選択します。

レート制限:

- デフォルトは毎分200リクエストです。
- 各認証済みユーザーに適用されます。リクエストが認証されていない場合、レート制限はIPアドレスに適用されます。
- レート制限を無効にするには、`0`に設定できます。

レート制限を超過したリクエストは、`auth.log`ファイルにログが記録されます。

例えば、200の制限を設定した場合、1分あたり200リクエストを超えるAPIエンドポイントへのリクエストはブロックされます。エンドポイントへのアクセスは1分後に再開されます。
