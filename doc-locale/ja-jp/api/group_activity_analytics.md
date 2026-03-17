---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループアクティビティアナリティクスAPI
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、グループアクティビティに関する情報を取得することができます。詳細については、[グループアクティビティアナリティクス](../user/group/manage.md#group-activity-analytics)を参照してください。

## グループの最近作成されたイシューの数を取得する {#retrieve-count-of-recently-created-issues-for-a-group}

指定されたグループの、最近作成されたイシューの数を取得します。

```plaintext
GET /analytics/group_activity/issues_count
```

パラメータは以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `group_path` | 文字列 | はい | グループパス |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/analytics/group_activity/issues_count?group_path=gitlab-org"
```

レスポンス例: 

```json
{ "issues_count": 10 }
```

## グループの最近作成されたマージリクエストの数を取得する {#retrieve-count-of-recently-created-merge-requests-for-a-group}

指定されたグループの、最近作成されたマージリクエストの数を取得します。

```plaintext
GET /analytics/group_activity/merge_requests_count
```

パラメータは以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `group_path` | 文字列 | はい | グループパス |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/analytics/group_activity/merge_requests_count?group_path=gitlab-org"
```

レスポンス例: 

```json
{ "merge_requests_count": 10 }
```

## グループに最近追加されたメンバーの数を取得する {#retrieve-count-of-members-recently-added-to-a-group}

指定されたグループに最近追加されたメンバーの数を取得します。

```plaintext
GET /analytics/group_activity/new_members_count
```

パラメータは以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `group_path` | 文字列 | はい | グループパス |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/analytics/group_activity/new_members_count?group_path=gitlab-org"
```

レスポンス例: 

```json
{ "new_members_count": 10 }
```
