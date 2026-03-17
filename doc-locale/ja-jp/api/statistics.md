---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: アプリケーション統計API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、GitLabのインスタンスから統計を取得することができます。

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

## アプリケーション統計を取得する {#retrieve-application-statistics}

GitLabのインスタンスから統計を取得します。

> [!note] 10,000未満の値の場合、このエンドポイントは正確なカウントを返します。10,000以上の値の場合、[TablesampleCountStrategy](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/database/count/tablesample_count_strategy.rb?ref_type=heads#L16)と[ReltuplesCountStrategy](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/database/count/reltuples_count_strategy.rb?ref_type=heads)の戦略が計算に使用される場合にのみ、このエンドポイントは概算データのみを返します。

```plaintext
GET /application/statistics
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/statistics"
```

レスポンス例: 

```json
{
   "forks": 10,
   "issues": 76,
   "merge_requests": 27,
   "notes": 954,
   "snippets": 50,
   "ssh_keys": 10,
   "milestones": 40,
   "users": 50,
   "groups": 10,
   "projects": 20,
   "active_users": 50
}
```
