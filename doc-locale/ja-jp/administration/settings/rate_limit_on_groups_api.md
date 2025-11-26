---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Groups APIのレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GroupsとプロジェクトAPIのレート制限は、GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152733)されました。[フラグ](../feature_flags/_index.md)の名前は`rate_limit_groups_and_projects_api`です。デフォルトでは無効になっています。
- GitLab 18.1で[一般公開](https://gitlab.com/gitlab-org/gitlab/-/issues/461316)になりました。機能フラグ`rate_limit_groups_and_projects_api`は削除されました。

{{< /history >}}

次の[groups API](../../api/groups.md)へのリクエストに対して、IPアドレスごと、ユーザーごとの1分あたりのレート制限を設定できます。

| 制限                                                           | デフォルト |
|-----------------------------------------------------------------|---------|
| [`GET /groups`](../../api/groups.md#list-groups)                | 200     |
| [`GET /groups/:id`](../../api/groups.md#get-a-single-group)     | 400     |
| [`GET /groups/:id/projects`](../../api/groups.md#list-projects) | 600     |

レート制限を変更するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **グループのAPIレート制限**を展開します。
1. 任意のレート制限の値を変更します。レート制限は、認証されたリクエストの場合はユーザーごと、認証されていないリクエストの場合はIPアドレスごとに適用されます。`0`に設定すると、レート制限が無効になります。
1. **変更を保存**を選択します。

レート制限:

- ユーザーが認証されている場合、ユーザーごとに適用されます。
- ユーザーが認証されていない場合、IPアドレスごとに適用されます。
- 0に設定すると、レート制限を無効にできます。

レート制限を超えたリクエストは、`auth.log`ファイルに記録されます。

たとえば、`GET /groups/:id`に400の制限を設定した場合、1分以内に400のレートを超えるAPIエンドポイントへのリクエストはブロックされます。エンドポイントへのアクセスは、1分経過後に復元されます。
