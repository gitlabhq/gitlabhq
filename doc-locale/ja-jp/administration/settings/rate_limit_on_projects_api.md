---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトAPIのレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- `rate_limit_for_unauthenticated_projects_api_access`という名前の[フラグ](../feature_flags/_index.md)とともに、GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112283)されました。デフォルトでは無効になっています。
- 2023年5月8日に[GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/391922)で有効になりました。
- デフォルトでは、GitLab 16.0の[GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119603)で有効になっています。
- GitLab 16.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120445)になりました。機能フラグ`rate_limit_for_unauthenticated_projects_api_access`は削除されました。
- グループおよびプロジェクトAPIのレート制限が、[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152733)されました（GitLab 17.1）。`rate_limit_groups_and_projects_api`という[flag](../feature_flags/_index.md)を使用します。デフォルトでは無効になっています。
- GitLab 18.1で[一般公開](https://gitlab.com/gitlab-org/gitlab/-/issues/461316)になりました。機能フラグ`rate_limit_groups_and_projects_api`は削除されました。

{{< /history >}}

次の[projects API](../../api/projects.md#list-all-projects)に対するリクエストについて、IPアドレスおよびユーザーごとにレート制限を設定できます。

| 制限                                                                                                       | デフォルト | 間隔 |
|-------------------------------------------------------------------------------------------------------------|---------|----------|
| [`GET /projects`](../../api/projects.md#list-all-projects)（未認証リクエスト）                       | 400     | 10分 |
| [`GET /projects`](../../api/projects.md#list-all-projects)（認証済みリクエスト）                         | 2000    | 10分 |
| [`GET /projects/:id`](../../api/projects.md#get-a-single-project)                                           | 400     | 1分 |
| [`GET /users/:user_id/projects`](../../api/projects.md#list-a-users-projects)                               | 300     | 1分 |
| [`GET /users/:user_id/contributed_projects`](../../api/projects.md#list-projects-a-user-has-contributed-to) | 100     | 1分 |
| [`GET /users/:user_id/starred_projects`](../../api/project_starring.md#list-projects-starred-by-a-user)     | 100     | 1分 |

レート制限を変更するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定** > **ネットワーク**を選択します。
1. **プロジェクトのAPIレート制限**を展開します。
1. 任意のレート制限の値を変更します。レート制限は、認証済みのリクエストではユーザーごとに、認証されていないリクエストではIPアドレスごとに、1分あたりの制限となります。レート制限を無効にするには、`0`に設定します。
1. **変更を保存**を選択します。

レート制限:

- ユーザーが認証されている場合、ユーザーごとに適用されます。
- ユーザーが認証されていない場合、IPアドレスごとに適用されます。
- レート制限を無効にするには、0に設定できます。

レート制限を超えたリクエストは、`auth.log`ファイルに記録されます。

たとえば、`GET /projects/:id`に400の制限を設定した場合、APIエンドポイントへのリクエストは、1分以内に400のレート制限を超えるとブロックされます。エンドポイントへのアクセスは、1分経過すると復元されます。
