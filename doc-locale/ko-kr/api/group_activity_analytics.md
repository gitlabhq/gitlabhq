---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 활동 분석 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 그룹 활동에 대한 정보를 검색합니다. 자세한 내용은 [그룹 활동 분석](../user/group/manage.md#group-activity-analytics)을 참고하세요.

## 그룹의 최근에 생성된 이슈 개수 검색 {#retrieve-count-of-recently-created-issues-for-a-group}

지정된 그룹의 최근에 생성된 이슈 개수를 검색합니다.

```plaintext
GET /analytics/group_activity/issues_count
```

매개변수:

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `group_path` | 문자열 | 예 | 그룹 경로 |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/analytics/group_activity/issues_count?group_path=gitlab-org"
```

응답 예시:

```json
{ "issues_count": 10 }
```

## 그룹의 최근에 생성된 머지 리퀘스트 개수 검색 {#retrieve-count-of-recently-created-merge-requests-for-a-group}

지정된 그룹의 최근에 생성된 머지 리퀘스트 개수를 검색합니다.

```plaintext
GET /analytics/group_activity/merge_requests_count
```

매개변수:

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `group_path` | 문자열 | 예 | 그룹 경로 |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/analytics/group_activity/merge_requests_count?group_path=gitlab-org"
```

응답 예시:

```json
{ "merge_requests_count": 10 }
```

## 그룹에 최근에 추가된 멤버 개수 검색 {#retrieve-count-of-members-recently-added-to-a-group}

지정된 그룹에 최근에 추가된 멤버 개수를 검색합니다.

```plaintext
GET /analytics/group_activity/new_members_count
```

매개변수:

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `group_path` | 문자열 | 예 | 그룹 경로 |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/analytics/group_activity/new_members_count?group_path=gitlab-org"
```

응답 예시:

```json
{ "new_members_count": 10 }
```
