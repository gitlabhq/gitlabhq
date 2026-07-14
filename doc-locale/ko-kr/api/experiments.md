---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 실험 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

이 API를 사용하여 A/B 실험과 상호 작용합니다. 이 API는 내부 사용만을 위한 것입니다.

전제 조건:

- [GitLab 팀 구성원](https://gitlab.com/groups/gitlab-com/-/group_members)이어야 합니다.

## 모든 실험 나열 {#list-all-experiments}

GitLab 인스턴스의 모든 실험을 나열합니다. 각 실험에는 실험이 전역적으로 활성화되어 있는지 또는 특정 컨텍스트에서만 활성화되어 있는지를 나타내는 `enabled` 상태가 있습니다.

```plaintext
GET /experiments
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/experiments"
```

응답 예시:

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
