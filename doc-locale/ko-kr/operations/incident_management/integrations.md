---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "웹후크를 사용하여 외부 소스에서 경고를 수신하고, 경고 필드를 매핑하고, 테스트 경고를 트리거하며, Prometheus 및 Opsgenie과 같은 도구와 통합합니다."
title: 연동
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab은 웹후크 수신기를 통해 모든 소스에서 경고를 수신할 수 있습니다. [경고 알림](alerts.md)은 대기 중인 로테이션에 대해 [페이징을 트리거](paging.md#paging)하거나 [인시던트를 생성](manage_incidents.md#from-an-alert)하는 데 사용할 수 있습니다.

## 연동 목록 {#integrations-list}

Maintainer 또는 Owner 역할이 있으면 프로젝트의 사이드바 메뉴에서 **설정** > **모니터링**으로 이동하여 구성된 경고 연동 목록을 볼 수 있으며, **경고** 섹션을 확장할 수 있습니다. 목록에 연동 이름, 유형 및 상태(활성화 또는 비활성화)가 표시됩니다:

![구성된 경고 세부 정보를 보여주는 표](img/integrations_list_v13_5.png)

## 구성 {#configuration}

GitLab은 구성하는 HTTP 엔드포인트를 통해 경고를 수신할 수 있습니다.

### 단일 경고 엔드포인트 {#single-alerting-endpoint}

GitLab 프로젝트에서 경고 엔드포인트를 활성화하면 JSON 형식의 경고 페이로드를 수신할 수 있습니다. 언제든지 [페이로드를 사용자 지정](#customize-the-alert-payload-outside-of-gitlab)할 수 있습니다.

1. 프로젝트의 Maintainer 역할을 가진 사용자로 GitLab에 로그인합니다.
1. 프로젝트에서 **설정** > **모니터링**으로 이동합니다.
1. **경고** 섹션을 확장하고, **통합 유형 선택** 드롭다운 목록에서 Prometheus의 경우 **Prometheus**를 선택하거나 다른 모니터링 도구의 경우 **HTTP 엔드포인트**를 선택합니다.
1. **활성** 경고 설정을 전환합니다. 웹후크 구성을 위한 URL 및 인증 키는 연동을 저장한 후 **자격 증명 보기** 탭에서 사용할 수 있습니다. 외부 서비스에 URL 및 인증 키를 입력해야 합니다.

### 경고 엔드포인트 {#alerting-endpoints}

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[GitLab Premium](https://about.gitlab.com/pricing/)에서는 JSON 형식의 모든 외부 소스에서 경고를 수신하는 여러 고유한 경고 엔드포인트를 만들 수 있으며, [페이로드를 사용자 지정](#customize-the-alert-payload-outside-of-gitlab)할 수 있습니다.

1. 프로젝트의 Maintainer 역할을 가진 사용자로 GitLab에 로그인합니다.
1. 프로젝트에서 **설정** > **모니터링**으로 이동합니다.
1. **경고** 섹션을 확장합니다.
1. 만들려는 각 엔드포인트에 대해:

   1. **새 통합 추가**를 선택합니다.
   1. **통합 유형 선택** 드롭다운 목록에서 Prometheus의 경우 **Prometheus**를 선택하거나 다른 모니터링 도구의 경우 **HTTP 엔드포인트**를 선택합니다. 세부 정보 보기
   1. 연동 이름을 입력합니다.
   1. **활성** 경고 설정을 전환합니다. 웹후크 구성을 위한 **URL** 및 **Authorization Key**는 연동을 저장한 후 **자격 증명 보기** 탭에서 사용할 수 있습니다. 외부 서비스에 URL 및 인증 키를 입력해야 합니다.
   1. 선택 사항. 모니터링 도구의 경고 필드를 GitLab 필드에 매핑하려면 샘플 페이로드를 입력하고 **Parse payload for custom mapping**을 선택합니다. 유효한 JSON이 필요합니다. 샘플 페이로드를 업데이트하면 필드도 다시 매핑해야 합니다. Prometheus 연동의 경우 전체 페이로드 대신 페이로드의 `alerts` 키에서 단일 경고를 입력합니다.

   1. 선택 사항. 유효한 샘플 페이로드를 제공한 경우 **페이로드 경고 키**의 각 값을 선택하여 [**GitLab 경고 키**에 매핑](#map-fields-in-custom-alerts)합니다.
   1. 연동을 저장하려면 **Save Integration**을 선택합니다. 원하는 경우 연동을 만든 후 연동의 **테스트 경고 전송** 탭에서 테스트 경고를 보낼 수 있습니다.

새로운 HTTP 엔드포인트가 [연동 목록](#integrations-list)에 표시됩니다. 연동 목록의 오른쪽에서 {{< icon name="settings" >}} 설정 아이콘을 선택하여 연동을 편집할 수 있습니다.

#### 사용자 지정 경고에서 필드 매핑 {#map-fields-in-custom-alerts}

모니터링 도구의 경고 형식을 GitLab 경고와 통합할 수 있습니다. [경고 목록](alerts.md#alert-list) 및 [경고 세부 정보 페이지](alerts.md#alert-details-page)에 올바른 정보를 표시하려면 [HTTP 엔드포인트를 만들](#alerting-endpoints) 때 경고의 필드를 GitLab 필드에 매핑합니다:

![경고 관리 목록](img/custom_alert_mapping_v13_11.png)

### Alertmanager에 연동 자격 증명 추가(Prometheus 연동만) {#add-integration-credentials-to-alertmanager-prometheus-integrations-only}

Prometheus 경고 알림을 GitLab으로 보내려면 [Prometheus 연동](#single-alerting-endpoint)에서 URL 및 인증 키를 복사하여 Prometheus Alertmanager 구성의 [`webhook_configs`](https://prometheus.io/docs/alerting/latest/configuration/#webhook_config) 섹션에 입력합니다:

```yaml
receivers:
  - name: gitlab
    webhook_configs:
      - http_config:
          authorization:
            type: Bearer
            credentials: 1234567890abdcdefg
        send_resolved: true
        url: http://IP_ADDRESS:PORT/root/manual_prometheus/prometheus/alerts/notify.json
        # Rest of configuration omitted
        # ...
```

## GitLab 외부에서 경고 페이로드 사용자 지정 {#customize-the-alert-payload-outside-of-gitlab}

### 예상되는 HTTP 요청 속성 {#expected-http-request-attributes}

[사용자 지정 매핑](#map-fields-in-custom-alerts)이 없는 HTTP 엔드포인트의 경우 다음 매개변수를 전송하여 페이로드를 사용자 지정할 수 있습니다. 모든 필드는 선택사항입니다. 들어오는 경고에 `Title` 필드에 대한 값이 없으면 기본값 `New: Alert`이 적용됩니다.

| 속성                  | 형식            | 설명 |
| ------------------------- | --------------- | ----------- |
| `title`                   | 문자열          | 경고의 제목입니다.|
| `description`             | 문자열          | 문제에 대한 고급 요약입니다. |
| `start_time`              | 날짜/시간        | 경고의 시간입니다. 제공되지 않으면 현재 시간이 사용됩니다. |
| `end_time`                | 날짜/시간        | 경고의 해결 시간입니다. 제공되면 경고가 해결됩니다. |
| `service`                 | 문자열          | 영향을 받는 서비스입니다. |
| `monitoring_tool`         | 문자열          | 관련 모니터링 도구의 이름입니다. |
| `hosts`                   | 문자열 또는 배열 | 이 인시던트가 발생한 위치에 해당하는 하나 이상의 호스트입니다. |
| `severity`                | 문자열          | 경고의 심각도입니다. 대소문자를 구분하지 않습니다. 다음 중 하나일 수 있습니다: `critical`, `high`, `medium`, `low`, `info`, `unknown`. 값이 없거나 이 목록에 없으면 `critical`로 기본 설정됩니다. |
| `fingerprint`             | 문자열 또는 배열 | 경고의 고유 식별자입니다. 동일한 경고의 발생을 그룹화하는 데 사용할 수 있습니다. `generic_alert_fingerprinting` 기능이 활성화되면 페이로드를 기반으로 지문이 자동으로 생성됩니다(`start_time`, `end_time` 및 `hosts` 매개변수 제외). |
| `gitlab_environment_name` | 문자열          | 관련된 GitLab [환경](../../ci/environments/_index.md)의 이름입니다. [대시보드에 경고 표시](../../user/operations_dashboard/_index.md#adding-a-project-to-the-dashboard)하는 데 필요합니다. |

경고의 페이로드에 사용자 지정 필드를 추가할 수도 있습니다. 추가 매개변수의 값은 원시 유형(예: 문자열 또는 숫자)으로 제한되지 않으며 중첩된 JSON 개체일 수 있습니다. 예를 들어:

```json
{ "foo": { "bar": { "baz": 42 } } }
```

> [!note]
> 요청이 [페이로드 애플리케이션 제한](../../administration/instance_limits.md#generic-alert-json-payloads)보다 작은지 확인하세요.

#### 예제 요청 본문 {#example-request-body}

예제 페이로드:

```json
{
  "title": "Incident title",
  "description": "Short description of the incident",
  "start_time": "2019-09-12T06:00:55Z",
  "service": "service affected",
  "monitoring_tool": "value",
  "hosts": "value",
  "severity": "high",
  "fingerprint": "d19381d4e8ebca87b55cda6e8eee7385",
  "foo": {
    "bar": {
      "baz": 42
    }
  }
}
```

### 예상되는 Prometheus 요청 속성 {#expected-prometheus-request-attributes}

경고는 Prometheus [웹후크 수신기](https://prometheus.io/docs/alerting/latest/configuration/#webhook_config)에 맞게 형식을 지정해야 합니다.

최상위 필수 속성:

- `alerts`
- `commonAnnotations`
- `commonLabels`
- `externalURL`
- `groupKey`
- `groupLabels`
- `receiver`
- `status`
- `version`

Prometheus 페이로드의 `alerts`에서 배열의 각 항목에 대해 GitLab 경고가 생성됩니다. 아래 나열된 중첩된 매개변수를 변경하여 GitLab 경고를 구성할 수 있습니다.

| 속성                                                                  | 형식     | 필수 | 설명                          |
| -------------------------------------------------------------------------- | -------- | -------- | ------------------------------------ |
| `annotations/title`, `annotations/summary` 또는 `labels/alertname` 중 하나   | 문자열   | 예      | 경고의 제목입니다.              |
| `startsAt`                                                                 | 날짜/시간 | 예      | 경고의 시작 시간입니다.         |
| `annotations/description`                                                  | 문자열   | 아니요       | 문제에 대한 고급 요약입니다. |
| `annotations/gitlab_incident_markdown`                                     | 문자열   | 아니요       | [GitLab Flavored Markdown](../../user/markdown.md)을 경고에서 생성된 모든 인시던트에 추가합니다. |
| `annotations/runbook`                                                      | 문자열   | 아니요       | 이 경고를 관리하는 방법에 대한 설명서 또는 지침으로의 링크입니다. |
| `endsAt`                                                                   | 날짜/시간 | 아니요       | 경고의 해결 시간입니다.    |
| `g0.expr` 쿼리 매개변수(in `generatorUrl`                                | 문자열   | 아니요       | 관련 메트릭의 쿼리입니다.          |
| `labels/gitlab_environment_name`                                           | 문자열   | 아니요       | 관련된 GitLab [환경](../../ci/environments/_index.md)의 이름입니다. [대시보드에 경고 표시](../../user/operations_dashboard/_index.md#adding-a-project-to-the-dashboard)하는 데 필요합니다. |
| `labels/severity`                                                          | 문자열   | 아니요       | 경고의 심각도입니다. [Prometheus 심각도 옵션](#prometheus-severity-options) 중 하나여야 합니다. 값이 없거나 이 목록에 없으면 `critical`로 기본 설정됩니다. |
| `status`                                                                   | 문자열   | 아니요       | Prometheus의 경고 상태입니다. 값이 'resolved'이면 경고가 해결됩니다. |
| `annotations/gitlab_y_label`, `annotations/title`, `annotations/summary` 또는 `labels/alertname` 중 하나 | 문자열 | 아니요 | [GitLab Flavored Markdown](../../user/markdown.md)에 이 경고의 메트릭을 포함할 때 사용할 Y축 레이블입니다. |

`annotations` 아래에 포함된 추가 속성은 [경고 세부 정보 페이지](alerts.md#alert-details-page)에서 사용할 수 있습니다. 다른 모든 속성은 무시됩니다.

속성은 원시 유형(예: 문자열 또는 숫자)으로 제한되지 않으며 중첩된 JSON 개체일 수 있습니다. 예를 들어:

```json
{
    "target": {
        "user": {
            "id": 42
        }
    }
}
```

> [!note]
> 요청이 [페이로드 애플리케이션 제한](../../administration/instance_limits.md#generic-alert-json-payloads)보다 작은지 확인하세요.

#### Prometheus 심각도 옵션 {#prometheus-severity-options}

Prometheus의 경고는 [경고 심각도](alerts.md#alert-severity)에 대한 다음 값(대소문자 구분 안 함) 중 하나를 제공할 수 있습니다:

- **치명적**: `critical`, `s1`, `p1`, `emergency`, `fatal`
- **높음**: `high`, `s2`, `p2`, `major`, `page`
- **중간**: `medium`, `s3`, `p3`, `error`, `alert`
- **낮음**: `low`, `s4`, `p4`, `warn`, `warning`
- **정보**: `info`, `s5`, `p5`, `debug`, `information`, `notice`

심각도가 없거나 이 목록에 없으면 `critical`로 기본 설정됩니다.

#### Prometheus 경고 예제 {#example-prometheus-alert}

경고 규칙 예제:

```yaml
groups:
- name: example
  rules:
  - alert: ServiceDown
    expr: up == 0
    for: 5m
    labels:
      severity: high
    annotations:
      title: "Example title"
      runbook: "http://example.com/my-alert-runbook"
      description: "Service has been down for more than 5 minutes."
      gitlab_y_label: "y-axis label"
      foo:
        bar:
          baz: 42
```

요청 페이로드 예제:

```json
{
  "version" : "4",
  "groupKey": null,
  "status": "firing",
  "receiver": "",
  "groupLabels": {},
  "commonLabels": {},
  "commonAnnotations": {},
  "externalURL": "",
  "alerts": [{
    "startsAt": "2022-010-30T11:22:40Z",
    "generatorURL": "http://host?g0.expr=up",
    "endsAt": null,
    "status": "firing",
    "labels": {
      "gitlab_environment_name": "production",
      "severity": "high"
    },
    "annotations": {
      "title": "Example title",
      "runbook": "http://example.com/my-alert-runbook",
      "description": "Service has been down for more than 5 minutes.",
      "gitlab_y_label": "y-axis label",
      "foo": {
        "bar": {
          "baz": 42
        }
      }
    }
  }]
}
```

> [!note]
> [테스트 경고를 트리거](#triggering-test-alerts)할 때 예제에 표시된 대로 전체 페이로드를 입력합니다. [사용자 지정 매핑을 구성](#map-fields-in-custom-alerts)할 때 샘플 페이로드로 `alerts` 배열의 첫 번째 항목만 입력합니다.

## 인증 {#authorization}

다음 인증 방법이 허용됩니다:

- Bearer 인증 헤더
- 기본 인증

`<authorization_key>` 및 `<url>` 값은 경고 연동을 구성할 때 확인할 수 있습니다.

### Bearer 인증 헤더 {#bearer-authorization-header}

인증 키를 Bearer 토큰으로 사용할 수 있습니다:

```shell
curl --request POST \
  --data '{"title": "Incident title"}' \
  --header "Authorization: Bearer <authorization_key>" \
  --header "Content-Type: application/json" \
  <url>
```

### 기본 인증 {#basic-authentication}

인증 키를 `password`으로 사용할 수 있습니다. `username`는 공백으로 남겨둡니다:

- username: `<blank>`
- password: `<authorization_key>`

```shell
curl --request POST \
  --data '{"title": "Incident title"}' \
  --header "Authorization: Basic <base_64_encoded_credentials>" \
  --header "Content-Type: application/json" \
  <url>
```

기본 인증은 URL에서 직접 자격 증명을 사용하여 사용할 수도 있습니다:

```shell
curl --request POST \
  --data '{"title": "Incident title"}' \
  --header "Content-Type: application/json" \
  <username:password@url>
```

> [!warning]
> URL에 인증 키를 사용하는 것은 안전하지 않습니다(서버 로그에 표시되므로). 도구에서 지원하면 이전에 설명한 헤더 옵션 중 하나를 사용하는 것이 좋습니다.

## 응답 본문 {#response-body}

JSON 응답 본문에는 요청 내에서 생성된 경고 목록이 포함됩니다:

```json
[
  {
    "iid": 1,
    "title": "Incident title"
  },
  {
    "iid": 2,
    "title": "Second Incident title"
  }
]
```

성공적인 응답은 `200` 응답 코드를 반환합니다.

## 테스트 경고 트리거 {#triggering-test-alerts}

[프로젝트 Maintainer 또는 Owner](../../user/permissions.md)가 연동을 구성한 후 테스트 경고를 트리거하여 연동이 제대로 작동하는지 확인할 수 있습니다.

1. Developer, Maintainer 또는 Owner 역할을 가진 사용자로 로그인합니다.
1. 프로젝트에서 **설정** > **모니터링**으로 이동합니다.
1. **경고**를 선택하여 섹션을 확장합니다.
1. [목록](#integrations-list)의 연동 오른쪽에서 {{< icon name="settings" >}} 설정 아이콘을 선택합니다.
1. **테스트 경고 전송** 탭을 선택하여 엽니다.
1. 페이로드 필드에 테스트 페이로드를 입력합니다(유효한 JSON이 필요함).
1. **전송**을 선택합니다.

GitLab은 테스트 결과에 따라 오류 또는 성공 메시지를 표시합니다.

## 동일한 경고 자동 그룹화 {#automatic-grouping-of-identical-alerts}

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab은 경고를 페이로드를 기준으로 그룹화합니다. 들어오는 경고가 다른 경고와 동일한 페이로드를 포함하면(`start_time` 및 `hosts` 속성 제외), GitLab은 이러한 경고를 함께 그룹화하고 [경고 관리 목록](incidents.md) 및 세부 정보 페이지에 카운터를 표시합니다.

기존 경고가 이미 `resolved`인 경우 GitLab은 대신 새 경고를 만듭니다.

![경고 관리 목록](img/alert_list_v13_1.png)

## 복구 경고 {#recovery-alerts}

HTTP 엔드포인트가 경고 종료 시간이 설정된 페이로드를 수신하면 GitLab의 경고가 자동으로 해결됩니다. [사용자 지정 매핑](#map-fields-in-custom-alerts)이 없는 HTTP 엔드포인트의 경우 예상 필드는 `end_time`입니다. 사용자 지정 매핑을 사용하면 예상 필드를 선택할 수 있습니다.

GitLab은 페이로드의 일부로 제공할 수 있는 `fingerprint` 값을 기반으로 해결할 경고를 결정합니다. 경고 속성 및 매핑에 대한 자세한 내용은 [GitLab 외부에서 경고 페이로드 사용자 지정](#customize-the-alert-payload-outside-of-gitlab)을 참조하세요.

경고가 해결될 때 관련 [인시던트를 자동으로 종료](manage_incidents.md#automatically-close-incidents-via-recovery-alerts)하도록 구성할 수도 있습니다.

## Opsgenie 경고에 링크 {#link-to-your-opsgenie-alerts}

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 13.2에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/3066)되었습니다.

{{< /history >}}

> [!warning]
> Opsgenie 및 기타 경고 도구와 [HTTP 엔드포인트 연동](#single-alerting-endpoint)을 통해 더 깊은 통합을 구축하고 있습니다. 따라서 GitLab 인터페이스에서 경고를 볼 수 있습니다.

[Opsgenie](https://www.atlassian.com/software/opsgenie)와의 GitLab 통합을 사용하여 경고를 모니터링할 수 있습니다.

Opsgenie 연동을 활성화하면 동시에 다른 GitLab 경고 서비스를 활성화할 수 없습니다.

Opsgenie 연동을 활성화하려면:

1. Maintainer 또는 Owner 역할을 가진 사용자로 로그인합니다.
1. **모니터링** > **경고**로 이동합니다.
1. **연동** 선택 상자에서 **Opsgenie**를 선택합니다.
1. **활성** 전환을 선택합니다.
1. **API URL** 필드에 `https://app.opsgenie.com/alert/list`과 같은 Opsgenie 연동의 기본 URL을 입력합니다.
1. **변경사항 저장**을 선택합니다.

연동을 활성화한 후 **경고** 페이지(**모니터링** > **경고**)로 이동한 다음 **View alerts in Opsgenie**를 선택합니다.
