---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 実験API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

このAPIを使用して、A/B実験を操作します。このAPIは、内部使用のみを目的としています。

前提要件: 

- [GitLabチームメンバー](https://gitlab.com/groups/gitlab-com/-/group_members)である必要があります。

## すべての実験をリストする {#list-all-experiments}

すべての実験のリストを取得します。各実験には、`enabled`ステータスがあり、実験がグローバルに有効になっているか、特定のコンテキストでのみ有効になっているかを示します。

```plaintext
GET /experiments
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/experiments"
```

レスポンス例:

```json
[
  {
    "key": "code_quality_walkthrough",
    "definition": {
      "name": "code_quality_walkthrough",
      "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/58900",
      "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/327229",
      "milestone": "13.12",
      "type": "experiment",
      "group": "group::activation",
      "default_enabled": false
    },
    "current_status": {
      "state": "conditional",
      "gates": [
        {
          "key": "boolean",
          "value": false
        },
        {
          "key": "percentage_of_actors",
          "value": 25
        }
      ]
    }
  },
  {
    "key": "ci_runner_templates",
    "definition": {
      "name": "ci_runner_templates",
      "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/58357",
      "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/326725",
      "milestone": "14.0",
      "type": "experiment",
      "group": "group::activation",
      "default_enabled": false
    },
    "current_status": {
      "state": "off",
      "gates": [
        {
          "key": "boolean",
          "value": false
        }
      ]
    }
  }
]
```
