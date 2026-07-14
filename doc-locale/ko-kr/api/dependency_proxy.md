---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 종속성 프록시 API
description: GitLab 종속성 프록시용 REST API 문서입니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [종속성 프록시](../user/packages/dependency_proxy/_index.md)를 관리합니다.

## 그룹의 종속성 프록시 삭제 예약 {#purge-the-dependency-proxy-for-a-group}

그룹의 캐시된 매니페스트 및 blob 삭제를 예약합니다. 이 엔드포인트는 그룹의 소유자 역할이 필요합니다.

```plaintext
DELETE /groups/:id/dependency_proxy/cache
```

| 특성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --request DELETE \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/groups/5/dependency_proxy/cache"
```
