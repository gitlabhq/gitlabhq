---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "Jira를 GitLab과 통합하여 실시간 인시던트 복제를 활성화하고, 실패율 변경과 서비스 복원 시간을 포함한 정확한 DORA 메트릭 추적을 지원합니다."
title: Jira to GitLab DORA 통합
---

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab을 사용하면 [DORA 메트릭](../../user/analytics/dora_metrics.md)을 확인하여 DevOps 성능을 측정할 수 있습니다. 4가지 메트릭은 다음과 같습니다:

- **배포 빈도**: 프로덕션에 대한 일일 평균 배포 수
- **변경을 위한 리드 타임**: 커밋을 프로덕션에 성공적으로 전달하는 데 걸린 초 수(코드 커밋부터 프로덕션에서 성공적으로 실행되는 코드까지)
- **실패율 변경**: 주어진 시간 동안 프로덕션에서 인시던트를 발생시키는 배포의 %
- **서비스 복원 시간**: 프로덕션 환경에서 인시던트가 열린 상태로 있던 중간 시간

처음 두 메트릭은 GitLab CI/CD 및 머지 리퀘스트에서 생성되는 반면, 마지막 두 메트릭은 [GitLab 인시던트](../../operations/incident_management/manage_incidents.md)가 생성되어야 합니다.

Jira를 인시던트 추적에 사용하는 팀의 경우, 인시던트를 Jira에서 GitLab으로 실시간으로 복제해야 합니다. 이 프로젝트는 해당 복제를 설정하는 방법을 안내합니다.

> [!note]
> 이슈 복제를 통해 Value Stream Analytics 메트릭(Lead Time, Issues Created, Issues Closed)을 생성하는 유사한 통합이 존재합니다. VSA 메트릭에 대해 이슈 복제에 관심이 있다면, [Jira to GitLab VSA 통합](jira_vsa.md)을 참조하세요.

## 아키텍처 {#architecture}

2개의 자동화 워크플로우를 만들어야 합니다:

1. Jira에서 생성될 때 GitLab 인시던트를 만듭니다.
1. Jira에서 해결될 때 GitLab 인시던트를 해결합니다.

### 인시던트 생성 {#incident-creation}

![Jira 인시던트가 GitLab에서 경고를 트리거하는 방법을 보여주는 워크플로우](img/jira_dora_creation_flow_v18_1.png)

### 인시던트 해결 {#incident-resolution}

![해결된 Jira 인시던트가 GitLab에서 인시던트 해결을 트리거하는 방법을 보여주는 워크플로우](img/jira_dora_resolution_flow_v18_1.png)

## 설정 {#setup}

### 필수 조건 {#pre-requisites}

이 가이드에서는 다음을 보유하고 있다고 가정합니다:

- GitLab Ultimate 라이선스
- 인시던트를 복제할 Jira 프로젝트

Jira는 Jira 라이선스에 따라 자동화 실행 빈도에 [제한](https://www.atlassian.com/software/jira/pricing)을 둡니다. 현재 제한 사항은 다음과 같습니다:

| **티어**   | **한도**                    |
|------------|------------------------------|
| Free       | 월 100회 실행           |
| Standard   | 월 1700회 실행          |
| Premium    | 사용자당 월 1000회 실행 |
| Enterprise | 무제한 실행               |

각 인시던트 생성은 1회 실행으로 계산되며, 각 인시던트 해결도 1회 실행으로 계산됩니다.

### GitLab 경고 끝점 {#gitlab-alert-endpoint}

먼저 GitLab에서 경고를 생성/해결하는 데 트리거될 수 있는 HTTP 끝점을 만들어야 하며, 이는 인시던트를 생성/해결합니다.

1. Jira 인시던트를 생성하려는 GitLab 프로젝트로 이동합니다. 사이드바에서 **설정** > **모니터링**으로 이동합니다. **경고** 섹션을 확장합니다.
1. **경고** 아래에서 **경고 설정** 탭으로 전환합니다. 다음 상자를 확인하고 **변경사항 저장**을 클릭합니다:
   - _인시던트를 생성합니다. 트리거된 각 경고에 대해 인시던트가 생성됩니다._
   - _복구 경고 알림이 경고를 해결할 때 관련 인시던트를 자동으로 닫습니다_
1. **경고** 아래에서 **현재 통합 상태** 탭으로 전환합니다. **새 통합 추가**를 클릭합니다. **Integration type**을 `HTTP Endpoint`로 설정하고, 이름을 지정(예: `Jira incident sync`)한 다음, **통합 활성화**를 **활성**으로 설정합니다. Jira 자동화 워크플로우를 설정한 후 경고 페이로드 매핑을 사용자 정의하기 위해 돌아올 것입니다.
1. **통합 저장**을 클릭합니다. "Integration successfully saved"라는 메시지가 나타나야 합니다. **URL 및 인증 키 보기**를 클릭합니다.
1. Jira 자동화 워크플로우 및 Lambda 함수를 설정할 때 끝점 URL과 인증 키가 필요하므로 나중에 참조할 수 있도록 저장합니다.

### Jira 인시던트 생성 워크플로우 {#jira-incident-creation-workflow}

Jira 인시던트가 생성될 때 GitLab 경고 끝점을 자동으로 트리거하려면 [Jira 자동화](https://community.atlassian.com/t5/Jira-articles/Automation-for-Jira-Send-web-request-using-Jira-REST-API/ba-p/1443828)를 사용합니다.

1. 인시던트를 관리하는 Jira 프로젝트로 이동합니다. 사이드바에서 **프로젝트 설정** > **Automation**으로 이동합니다(찾을 때까지 아래로 스크롤해야 할 수도 있습니다).
1. 여기서 Jira 자동화 워크플로우를 관리할 수 있습니다. 오른쪽 위에서 **Create rule**을 클릭합니다.
1. 트리거의 경우 **이슈 생성됨**을 검색하고 선택합니다. **저장**을 클릭합니다.
1. 다음으로 **IF: 조건 추가** 여기서 생성된 이슈가 인시던트와 관련이 있는지 확인하기 위해 확인할 조건을 지정할 수 있습니다. 이 가이드에서는 **Issue fields condition**을 선택합니다. **필드** 아래에서 **요약**을 선택하고, **Condition**은 **contains**로 설정하며, 값은 `incident`입니다. **저장**을 클릭합니다.
1. 트리거 및 조건이 설정되면 **THEN: 작업 추가** **Send web request**를 검색하고 선택합니다.
1. **Web request URL**을 이전 섹션의 GitLab **Webhook URL**로 설정합니다.
1. GitLab 문서에서 [끝점 인증 옵션](../../operations/incident_management/integrations.md#authorization)을 확인합니다. 이 가이드에서는 [Bearer 인증 헤더](../../operations/incident_management/integrations.md#bearer-authorization-header) 방법을 사용합니다. Jira 자동화 구성에서 다음 헤더를 추가합니다:

   | 이름 | 값 |
   | ------ | ------ |
   | Authorization | Bearer <GitLab 끝점 **인증 키** 이전 섹션> |
   | Content-Type | `application/json` |

   - `Authorization` 헤더를 "Hidden"으로 설정할 수도 있습니다.
1. **HTTP method**가 **POST**로 설정되어 있는지 확인하고, **Web request body**를 **Issue data (Jira format)**으로 설정합니다.
1. 마지막으로 **저장**을 클릭하고, 자동화 이름을 지정(예: `Jira incident creation`)한 다음, **Turn it on**을 클릭합니다. 오른쪽 위에서 **Return to list**를 클릭합니다.
1. 마지막으로 해야 할 일은 Jira 페이로드 값을 GitLab 경고 매개변수에 매핑하는 것입니다. **서비스 복원 시간** 메트릭에 대해 인시던트 해결도 설정할 계획이라면, 지금은 이 단계를 건너뜁니다. 그렇지 않으면 [Jira 페이로드 값을 GitLab 경고 매개변수에 매핑](#map-jira-payload-values-to-gitlab-alert-parameters)으로 이동하여 거기의 단계를 따릅니다.

페이로드 값을 매핑한 후에는 Jira에서 생성한 인시던트도 GitLab에서 생성됩니다. 이를 통해 **실패율 변경** DORA 메트릭을 볼 수 있습니다.

### Jira 인시던트 해결 워크플로우 {#jira-incident-resolution-workflow}

위에서 설명한 대로 다른 Jira 자동화 워크플로우를 만들되 다음 변경 사항을 적용합니다:

1. 트리거를 **Issue transitioned**로 설정합니다. "From status" 필드는 비워둘 수 있습니다. "To status" 필드는 워크플로우에 따라 해결된 인시던트를 나타내는 모든 상태로 설정할 수 있습니다(예: `Closed`, `Done`, `Resolved`, `Completed`).
1. 자동화 이름을 적절하게 지정합니다(예: `Jira incident close`).

### Jira 페이로드 값을 GitLab 경고 매개변수에 매핑 {#map-jira-payload-values-to-gitlab-alert-parameters}

1. Jira 자동화 워크플로우를 만든 후 방금 만든 워크플로우를 클릭하고 **Then: 웹 요청 전송**
1. **Validate your web request configuration** 섹션을 확장하고 테스트할 _resolved_ 이슈 키를 입력합니다(사용할 수 있는 기존 이슈 키가 있어야 함). **검증**을 클릭합니다.
1. **Request POST** 섹션을 확장하고 **Payload** 섹션을 확장합니다. 전체 페이로드를 복사합니다.
1. GitLab 프로젝트로 돌아가서 **설정** > **모니터링** > **경고** > **Current Integrations**로 이동합니다. 이전에 만든 통합 옆의 '설정' 아이콘을 클릭하고 **상세 설정** 탭으로 전환합니다.
1. **Customize alert payload mapping** 아래에 3단계에서 Jira에서 복사한 페이로드를 붙여넣습니다. 그런 다음 **페이로드 필드 파싱**을 클릭합니다.
1. 아래 표시된 대로 필드를 매핑합니다:

   | GitLab 경고 키 | 페이로드 경고 키 |
   | ------ | ------ |
   | Title | issue.fields.summary |
   | 설명 | issue.fields.status.description |
   | End time | issue.fields.resolutiondate<sup>1</sup> |
   | Monitoring tool | issue.fields.reporter.accountType |
   | 심각도 | issue.fields.priority.name |
   | Fingerprint | issue.key |
   | Environment | issue.fields.project.name |

<sup>1</sup> 인시던트 해결 자동화를 설정한 경우에만 필요합니다. 이 필드가 옵션으로 나타나지 않으면 위의 2단계에서 테스트할 _resolved_ 이슈 키를 입력했는지 확인합니다.

1. 마지막으로 **통합 저장**을 클릭합니다.

이 시점에서 Jira에서 해결한 인시던트도 GitLab에서 해결됩니다. 이를 통해 **서비스 복원 시간** DORA 메트릭을 볼 수 있습니다.

## 리소스 {#resources}

- [DORA 메트릭](../../user/analytics/dora_metrics.md)
  - [Jira를 사용하여 DORA 메트릭 측정](../../user/analytics/dora_metrics.md#with-jira)
- [GitLab 인시던트 관리](../../operations/incident_management/manage_incidents.md)
- [GitLab HTTP 끝점](../../operations/incident_management/integrations.md#alerting-endpoints)
  - [GitLab HTTP 끝점 인증](../../operations/incident_management/integrations.md#authorization)
  - [GitLab 경고 매개변수](../../operations/incident_management/integrations.md#customize-the-alert-payload-outside-of-gitlab)
  - [GitLab 복구 경고](../../operations/incident_management/integrations.md#recovery-alerts)
- [웹 요청을 사용한 Jira 자동화](https://community.atlassian.com/t5/Jira-articles/Automation-for-Jira-Send-web-request-using-Jira-REST-API/ba-p/1443828)
