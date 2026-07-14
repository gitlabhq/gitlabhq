---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 클러스터 검색 API(인증서 기반)(더 이상 사용되지 않음)
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> 이 기능은 GitLab 14.5에서 [더 이상 사용되지 않습니다](https://gitlab.com/groups/gitlab-org/configure/-/epics/8).

## 인증서 기반 클러스터 검색 {#retrieve-certificate-based-clusters}

그룹, 서브그룹 또는 프로젝트에 등록된 인증서 기반 클러스터를 검색합니다. 비활성화된 클러스터와 활성화된 클러스터도 반환됩니다.

```plaintext
GET /discover-cert-based-clusters
```

매개변수:

| 속성 | 유형           | 필수 | 설명                                                                   |
| --------- | -------------- | -------- | ----------------------------------------------------------------------------- |
| `group_id`      | 정수 또는 문자열 | 예      | 그룹의 ID |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/discover-cert-based-clusters?group_id=1"
```

응답 예시:

```json
{
  "groups": {
    "my-clusters-group": [
      {
        "id": 2,
        "name": "group-cluster-1"
      }
    ],
    "my-clusters-group/subgroup1/subsubgroup1": [
      {
        "id": 4,
        "name": "subsubgroup-cluster"
      }
    ]
  },
  "projects": {
    "my-clusters-group/subgroup1/subsubgroup1/subsubgroup-project-with-cluster": [
      {
        "id": 3,
        "name": "subsubgroup-project-cluster"
      }
    ],
    "my-clusters-group/project1-with-cluster": [
      {
        "id": 1,
        "name": "test"
      }
    ]
  }
}
```
