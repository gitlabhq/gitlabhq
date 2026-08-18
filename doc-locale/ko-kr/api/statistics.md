---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 애플리케이션 통계 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 GitLab 인스턴스에서 통계를 검색할 수 있습니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

## 애플리케이션 통계 검색 {#retrieve-application-statistics}

GitLab 인스턴스에서 통계를 검색합니다.

> [!note]
> 10,000 미만의 값의 경우 이 엔드포인트는 정확한 개수를 반환합니다. 10,000 이상의 값의 경우 이 엔드포인트는 계산에 [TablesampleCountStrategy](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/database/count/tablesample_count_strategy.rb?ref_type=heads#L16) 및 [ReltuplesCountStrategy](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/database/count/reltuples_count_strategy.rb?ref_type=heads) 전략을 사용할 때만 대략적인 데이터를 반환합니다.

```plaintext
GET /application/statistics
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/statistics"
```

응답 예시:

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
