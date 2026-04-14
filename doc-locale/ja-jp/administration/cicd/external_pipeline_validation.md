---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 外部パイプライン検証
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

外部サービスを使用して、パイプラインが作成される前にそれを検証できます。

GitLabは、パイプラインデータをペイロードとして、外部サービスURLにPOSTリクエストを送信します。外部サービスからのレスポンスコードによって、GitLabがパイプラインを受け入れるか拒否するかが決まります。レスポンスが次の場合は:

- `200`の場合、パイプラインは受け入れられます。
- `406`の場合、パイプラインは拒否されます。
- その他のコードの場合、パイプラインは受け入れられ、記録されます。

エラーが発生したり、リクエストがタイムアウトしたりした場合、パイプラインは受け入れられます。

外部検証サービスによって拒否されたパイプラインは作成されず、GitLab UIまたはAPIのパイプラインリストには表示されません。UIでパイプラインを作成し、それが拒否された場合、`Pipeline cannot be run. External validation failed`が表示されます。

## 外部パイプラインの検証を設定する {#configure-external-pipeline-validation}

外部パイプラインの検証を設定するには、[`EXTERNAL_VALIDATION_SERVICE_URL`環境変数](../environment_variables.md)を追加し、外部サービスURLに設定します。

デフォルトでは、外部サービスへのリクエストは5秒後にタイムアウトします。デフォルトをオーバーライドするには、`EXTERNAL_VALIDATION_SERVICE_TIMEOUT`環境変数を必要な秒数に設定します。

## ペイロードスキーマ {#payload-schema}

{{< history >}}

- `tag_list`は、GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/335904)されました。

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

`namespace`フィールドは、[GitLab PremiumおよびUltimate](https://about.gitlab.com/pricing/)でのみ利用可能です。
