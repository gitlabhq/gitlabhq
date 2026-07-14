---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 외부 파이프라인 유효성 검사
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

외부 서비스를 사용하여 파이프라인을 만들기 전에 유효성을 검사할 수 있습니다.

GitLab은 파이프라인 데이터를 페이로드로 사용하여 외부 서비스 URL로 POST 요청을 보냅니다. 외부 서비스의 응답 코드는 GitLab이 파이프라인을 수락할지 거부할지를 결정합니다. 응답이 다음과 같은 경우:

- `200`, 파이프라인이 수락됩니다.
- `406`, 파이프라인이 거부됩니다.
- 다른 코드의 경우, 파이프라인이 수락되고 기록됩니다.

오류가 발생하거나 요청 시간이 초과되면 파이프라인이 수락됩니다.

외부 검증 서비스에 의해 거부된 파이프라인은 생성되지 않으며, GitLab UI 또는 API의 파이프라인 목록에 나타나지 않습니다. UI에서 거부된 파이프라인을 생성하면 `Pipeline cannot be run. External validation failed`이 표시됩니다.

## 외부 파이프라인 검증 구성 {#configure-external-pipeline-validation}

외부 파이프라인 검증을 구성하려면 [`EXTERNAL_VALIDATION_SERVICE_URL` 환경 변수](../environment_variables.md)를 추가하고 외부 서비스 URL로 설정합니다.

기본적으로 외부 서비스에 대한 요청은 5초 후 시간이 초과됩니다. 기본값을 재정의하려면 `EXTERNAL_VALIDATION_SERVICE_TIMEOUT` 환경 변수를 필요한 초 수로 설정합니다.

## 페이로드 스키마 {#payload-schema}

{{< history >}}

- `tag_list` [GitLab 16.11에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/335904).

{{< /history >}}

```json
{
  "type": "object",
  "required" : [
    "project",
    "user",
    "credit_card",
    "pipeline",
    "builds",
    "total_builds_count",
    "namespace"
  ],
  "properties" : {
    "project": {
      "type": "object",
      "required": [
        "id",
        "path",
        "created_at",
        "shared_runners_enabled",
        "group_runners_enabled"
      ],
      "properties": {
        "id": { "type": "integer" },
        "path": { "type": "string" },
        "created_at": { "type": ["string", "null"], "format": "date-time" },
        "shared_runners_enabled": { "type": "boolean" },
        "group_runners_enabled": { "type": "boolean" }
      }
    },
    "user": {
      "type": "object",
      "required": [
        "id",
        "username",
        "email",
        "created_at"
      ],
      "properties": {
        "id": { "type": "integer" },
        "username": { "type": "string" },
        "email": { "type": "string" },
        "created_at": { "type": ["string", "null"], "format": "date-time" },
        "current_sign_in_ip": { "type": ["string", "null"] },
        "last_sign_in_ip": { "type": ["string", "null"] },
        "sign_in_count": { "type": "integer" }
      }
    },
    "credit_card": {
      "type": "object",
      "required": [
        "similar_cards_count",
        "similar_holder_names_count"
      ],
      "properties": {
        "similar_cards_count": { "type": "integer" },
        "similar_holder_names_count": { "type": "integer" }
      }
    },
    "pipeline": {
      "type": "object",
      "required": [
        "sha",
        "ref",
        "type"
      ],
      "properties": {
        "sha": { "type": "string" },
        "ref": { "type": "string" },
        "type": { "type": "string" }
      }
    },
    "builds": {
      "type": "array",
      "items": {
        "type": "object",
        "required": [
          "name",
          "stage",
          "image",
          "tag_list",
          "services",
          "script"
        ],
        "properties": {
          "name": { "type": "string" },
          "stage": { "type": "string" },
          "image": { "type": ["string", "null"] },
          "tag_list": { "type": ["array", "null"] },
          "services": {
            "type": ["array", "null"],
            "items": { "type": "string" }
          },
          "script": {
            "type": "array",
            "items": { "type": "string" }
          }
        }
      }
    },
    "total_builds_count": { "type": "integer" },
    "namespace": {
      "type": "object",
      "required": [
        "plan",
        "trial"
      ],
      "properties": {
        "plan": { "type": "string" },
        "trial": { "type": "boolean" }
      }
    },
    "provisioning_group": {
      "type": "object",
      "required": [
        "plan",
        "trial"
      ],
      "properties": {
        "plan": { "type": "string" },
        "trial": { "type": "boolean" }
      }
    }
  }
}
```

`namespace` 필드는 [GitLab Premium 및 Ultimate](https://about.gitlab.com/pricing/)에서만 사용 가능합니다.
