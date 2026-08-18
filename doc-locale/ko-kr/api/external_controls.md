---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 외부 컨트롤 API
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

외부 컨트롤 API를 사용하여 외부 서비스를 사용하는 검사의 상태를 설정합니다.

주기적 ping 기능을 사용하여 외부 컨트롤을 구성할 수 있습니다. ping이 활성화된 경우(기본값), GitLab은 컨트롤 상태를 `pending`로 12시간마다 자동으로 재설정합니다. ping이 비활성화된 경우, 컨트롤 상태는 API 호출을 통해서만 업데이트됩니다.

## 외부 컨트롤의 상태 설정 {#set-status-of-an-external-control}

{{< history >}}

- GitLab 17.11에서 [도입됨](https://gitlab.com/groups/gitlab-org/-/epics/13658).

{{< /history >}}

지정된 외부 컨트롤의 상태를 설정합니다. 이 작업을 사용하여 컨트롤이 외부 서비스에서 수행한 검사를 통과했거나 실패했음을 GitLab에 알립니다.

필수 조건

- 보안을 위해 HMAC, Timestamp 및 Nonce 인증을 사용해야 합니다.

```plaintext
PATCH /api/v4/projects/:id/compliance_external_controls/:external_control_id/status
```

HTTP 헤더:

| 헤더                |  유형   | 필수 | 설명                                                                                   |
| --------------------- | ------- | -------- | --------------------------------------------------------------------------------------------- |
| `X-Gitlab-Timestamp`  | 문자열  | 예      | 현재 Unix 타임스탬프입니다.                                                                       |
| `X-Gitlab-Nonce`      | 문자열  | 예      | 재생 공격을 방지하기 위한 임의 문자열 또는 토큰입니다.                                             |
| `X-Gitlab-Hmac-Sha256`| 문자열  | 예      | 요청의 HMAC-SHA256 서명입니다.                                                         |

HMAC-SHA256 서명을 계산하려면:

1. 다음 순서대로 이 값들을 연결합니다:
   - `X-Gitlab-Timestamp`
   - `X-Gitlab-Nonce`
   - 요청의 전체 경로
   - `status` 속성의 값입니다. `status=<status>`로 형식화됩니다.
1. 비밀 키를 사용하여 연결된 문자열의 HMAC-SHA256을 계산합니다.

지원되는 속성:

| 속성                | 유형    | 필수 | 설명                                                                                       |
| ------------------------ | ------- | -------- |---------------------------------------------------------------------------------------------------|
| `id`                     | 정수 | 예      | 프로젝트의 ID입니다.                                                                                  |
| `external_control_id`    | 정수 | 예      | 외부 컨트롤의 ID입니다.                                                                        |
| `status`                 | 문자열  | 예      | `pass`로 설정하면 컨트롤을 통과로 표시하거나 `fail`로 설정하면 실패로 표시합니다.                                |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                | 유형     | 설명                                   |
|--------------------------|----------|-----------------------------------------------|
| `status`                 | 문자열   | 컨트롤에 대해 설정된 상태입니다. |

요청 예시:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "X-Gitlab-Timestamp: <X-Gitlab-Timestamp>" \
  --header "X-Gitlab-Nonce: <X-Gitlab-Nonce>" \
  --header "X-Gitlab-Hmac-Sha256: <X-Gitlab-Hmac-Sha256>" \
  --header "Content-Type: application/json" \
  --data '{"status": "pass"}' \
  --url "https://gitlab.example.com/api/v4/projects/<id>/compliance_external_controls/<external_control_id>/status"
```

응답 예시:

```json
{
    "status":"pass"
}
```

## 관련 항목 {#related-topics}

- [규정 준수 프레임워크](../user/compliance/compliance_frameworks/_index.md)
