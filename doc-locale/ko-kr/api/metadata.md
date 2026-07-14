---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 메타데이터 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/357032)되었습니다.
- `enterprise` GitLab 15.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/103969)되었습니다.
- `kas.externalK8sProxyUrl` GitLab 17.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172373)되었습니다.

{{< /history >}}

지정된 GitLab 인스턴스의 메타데이터 정보를 검색합니다.

```plaintext
GET /metadata
GET /version
```

응답 본문 속성:

| 속성                 | 유형           | 설명                                                                                                                   |
|:--------------------------|:---------------|:------------------------------------------------------------------------------------------------------------------------------|
| `version`                 | 문자열         | GitLab 인스턴스의 버전입니다.                                                                                               |
| `revision`                | 문자열         | GitLab 인스턴스의 리비전입니다.                                                                                              |
| `kas`                     | 객체         | Kubernetes(KAS)용 GitLab 에이전트 서버의 메타데이터입니다.                                                                  |
| `kas.enabled`             | 부울        | KAS가 활성화되어 있는지 여부를 나타냅니다.                                                                                             |
| `kas.externalUrl`         | 문자열 또는 null | 에이전트가 KAS와 통신하는 데 사용하는 URL입니다. `null` `kas.enabled`가 `false`인 경우입니다.                                      |
| `kas.externalK8sProxyUrl` | 문자열 또는 null | Kubernetes 도구가 KAS Kubernetes API 프록시와 통신하는 데 사용하는 URL입니다. `null` `kas.enabled`가 `false`인 경우입니다. |
| `kas.version`             | 문자열 또는 null | KAS의 버전입니다. `null` `kas.enabled`가 `false`이거나 GitLab 인스턴스가 KAS에서 서버 정보를 가져오지 못한 경우입니다.         |
| `enterprise`              | 부울        | GitLab 인스턴스가 Enterprise Edition인지 여부를 나타냅니다.                                                                      |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/metadata"
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/version"
```

응답 예시:

```json
{
  "version": "18.1.1-ee",
  "revision": "ceb07b24cb0",
  "kas": {
    "enabled": true,
    "externalUrl": "grpc://gitlab.example.com:8150",
    "externalK8sProxyUrl": "https://gitlab.example.com:8150/k8s-proxy",
    "version": "18.1.1"
  },
  "enterprise": true
}
```
