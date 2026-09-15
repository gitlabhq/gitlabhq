---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: Jira에서 GitLab VSA 통합
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab [가치 흐름 분석(VSA)](../../user/group/value_stream_analytics/_index.md)은 개발 워크플로우에 대한 강력한 인사이트를 제공하며, 다음과 같은 주요 지표를 추적합니다:

- **리드 타임**: 이슈 생성부터 완료까지의 시간
- **이슈가 생성됨**: 주어진 기간 내에 생성된 새로운 이슈의 수
- **이슈가 닫힘**: 주어진 기간 내에 해결된 이슈의 수

Jira를 이슈 추적에 사용하고 GitLab을 개발에 활용하는 팀의 경우, 이 통합을 통해 Jira 이슈를 GitLab에 실시간으로 자동 복제할 수 있습니다. 이를 통해 팀이 기존 Jira 워크플로우를 변경할 필요 없이 정확한 VSA 지표를 보장합니다.

또한 이 통합은 GitLab **가치 흐름 대시보드**(Ultimate 전용)를 채우며, 주요 DevSecOps 지표를 제공하고 GitLab 프로젝트 또는 그룹의 **분석** > **분석 대시보드**에서 확인할 수 있습니다.

> [!note]
> 유사한 통합이 특정 DORA 지표(변경 실패율 및 서비스 복구 시간)를 생성하기 위한 인시던트 복제용으로 존재합니다. 인시던트 복제에 관심이 있으신 경우, [Jira 인시던트 복제기](jira_dora.md)를 참고하세요.

## 아키텍처 {#architecture}

Jira 자동화를 사용하여 2개의 자동화 워크플로우를 생성합니다:

1. Jira에서 생성된 경우 GitLab 이슈를 생성합니다
1. Jira에서 해결된 경우 GitLab 이슈를 닫습니다

### 이슈 생성 {#issue-creation}

Jira에서 새 이슈가 생성되면, 자동화 워크플로우는 GitLab 이슈 API에 POST 요청을 보내 지정된 GitLab 프로젝트에 해당하는 이슈를 생성합니다.

### 이슈 해결 {#issue-resolution}

Jira 이슈가 해결 상태(닫힘, 완료, 해결됨)로 전환되면, 자동화 워크플로우는 해당 GitLab 이슈를 닫기 위해 PUT 요청을 보냅니다.

## 설정 {#setup}

### 필수 조건 {#pre-requisites}

이 가이드에서는 다음을 보유하고 있다고 가정합니다:

- VSA 분석을 생성하려는 GitLab 프로젝트
- 이슈를 복제할 Jira 프로젝트
- GitLab Premium 또는 GitLab Ultimate 라이선스(가치 흐름 분석 기능용)

Jira는 Jira 라이선스에 따라 자동화 실행 빈도에 [제한](https://www.atlassian.com/software/jira/pricing)을 둡니다:

| **티어**   | **한도**                    |
|------------|------------------------------|
| Free       | 월 100회 실행           |
| Standard   | 월 1700회 실행          |
| Premium    | 사용자당 월 1000회 실행 |
| Enterprise | 무제한 실행               |

각 이슈 생성은 1회 실행으로 계산되며, 각 이슈 해결도 1회 실행으로 계산됩니다.

### GitLab 프로젝트 액세스 토큰 {#gitlab-project-access-token}

먼저 API를 통해 이슈를 생성하고 업데이트할 수 있는 필요한 권한을 가진 GitLab 프로젝트 액세스 토큰을 생성해야 합니다.

1. Jira 이슈를 복제하려는 GitLab 프로젝트로 이동합니다. 사이드바에서 **설정** > **Access Tokens**으로 이동합니다.
1. **새 토큰 추가**를 클릭합니다.
1. 다음 구성을 설정합니다:
   - **토큰 이름**: `Jira VSA Integration` (또는 설명적인 이름)
   - **만료일**: 보안 정책에 따라 설정합니다
   - **역할**: `Owner` (사용자 지정 이슈 ID를 설정하는 데 필요합니다)
   - **범위**: `api`을 확인합니다(전체 API 액세스)

**Important**: **소유자** 수준 액세스 토큰이 필요합니다. 왜냐하면 통합이 GitLab에서 이슈를 생성할 때 사용자 지정 이슈 ID를 강제로 설정해야 하기 때문입니다. 이를 통해 Jira 이슈가 닫혀도 자동화가 동일한 ID 매핑을 사용하여 해당 GitLab 이슈를 식별하고 닫을 수 있습니다. 소유자 역할이 없으면 GitLab API가 사용자 지정 이슈 ID 설정을 허용하지 않아 Jira 이슈 폐쇄와 GitLab 이슈 폐쇄 간의 동기화가 중단됩니다.

1. **Create project access token**을 클릭하고 생성된 토큰을 안전하게 저장합니다. Jira 자동화 설정에 필요합니다.

### Jira 이슈 생성 워크플로우 {#jira-issue-creation-workflow}

Jira 이슈가 생성될 때 자동으로 GitLab 이슈를 생성하려면 [Jira 자동화](https://community.atlassian.com/t5/Jira-articles/Automation-for-Jira-Send-web-request-using-Jira-REST-API/ba-p/1443828)를 사용합니다.

1. Jira 프로젝트로 이동합니다. 사이드바에서 **프로젝트 설정** > **Automation**로 이동합니다.
1. 오른쪽 위에서 **Create rule**을 클릭합니다.
1. 트리거의 경우 **이슈 생성됨**을 검색하고 선택합니다. **저장**을 클릭합니다.
1. *선택 사항*: 복제해야 할 이슈를 필터링하는 조건을 추가합니다. 예를 들어 **Issue fields condition**을 추가하여 특정 유형의 이슈나 특정 레이블이 있는 이슈만 복제하려고 할 수 있습니다.
1. **그러면: 작업 추가** **Send web request**를 검색하고 선택합니다.
1. 웹 요청을 구성합니다:
   - **Web request URL**: `https://gitlab.com/api/v4/projects/<GITLAB_PROJECT_ID>/issues` (`gitlab.com`을 자체 호스팅할 경우 GitLab 인스턴스 URL로 바꾸고, `<GITLAB_PROJECT_ID>`를 GitLab 프로젝트의 숫자 ID(예: `42718690`)로 바꿉니다)
   - **HTTP method**: **POST**
   - **Web request body**: **Custom data**
1. 다음 헤더를 추가합니다:

   | 이름 | 값 |
   | ------ | ------ |
   | Authorization | Bearer `<YOUR_GITLAB_TOKEN>` |
   | Content-Type | `application/json` |

   보안을 위해 인증 헤더를 "숨김"으로 설정합니다.
1. **Custom data** 필드에 다음을 입력합니다:

   ```json
   {
     "title": "{{issue.summary}}",
     "iid": {{issue.key.replace("VSA-", "1000")}}
   }
   ```

   `"VSA-"`을 Jira 프로젝트 접두사로 바꿉니다(예: Jira 이슈가 `PROJ-123`로 번호가 지정된 경우 `"PROJ-"`를 사용합니다). `1000`는 GitLab UI를 통해 직접 생성된 이슈와 충돌하지 않도록 추가되는 기본 숫자입니다. 필요에 따라 이 값을 조정할 수 있습니다.
1. **저장**을 클릭하고 자동화에 설명적인 이름을 지정하고(예: `Jira to GitLab Issue Creation`) **Turn it on**를 클릭합니다.

### Jira 이슈 해결 워크플로우 {#jira-issue-resolution-workflow}

Jira 이슈가 해결될 때 GitLab 이슈를 닫기 위한 두 번째 자동화 워크플로우를 생성합니다:

1. 생성 워크플로우의 1-2단계를 따라 새 규칙을 시작합니다.
1. 트리거를 **Issue transitioned**으로 설정합니다:
   - "시작 상태" 필드를 비워 둡니다
   - "끝 상태"를 해결된 상태로 설정합니다: `Closed`, `Done`, `Resolved` (Jira 워크플로우에 따라 조정합니다)
1. 조건을 건너뜁니다(필요한 경우 사용자 지정 조건을 추가합니다).
1. **Send web request** 작업을 다음과 같이 추가합니다:
   - **Web request URL**: `https://gitlab.com/api/v4/projects/<GITLAB_PROJECT_ID>/issues/{{issue.key.replace("<JIRA_PROJECT_PREFIX>-", "1000").urlEncode}}` (`gitlab.com`을 자체 호스팅할 경우 GitLab 인스턴스 URL로 바꾸고, `<GITLAB_PROJECT_ID>`를 GitLab 프로젝트의 숫자 ID로 바꾸고, `<JIRA_PROJECT_PREFIX>`를 `VSA` 또는 `PROJ`과 같은 Jira 프로젝트 접두사로 바꿉니다)
   - **HTTP method**: **PUT**
   - **Web request body**: **Custom data**
1. 생성 워크플로우와 동일한 헤더를 사용합니다.
1. **Custom data** 필드에 다음을 입력합니다:

   ```json
   {
     "state_event": "close"
   }
   ```

1. 자동화 규칙을 저장하고 설명적인 이름으로 활성화합니다(예: `Jira to GitLab Issue Closer`).

## 가치 흐름 분석 구성 {#value-stream-analytics-configuration}

자동화 워크플로우가 활성화되면 GitLab은 이슈 데이터를 수신하기 시작합니다. 분석에 액세스하는 방법은 다음과 같습니다:

### 가치 흐름 대시보드(자동 - Ultimate 전용) {#value-streams-dashboard-automatic---ultimate-only}

**가치 흐름 대시보드**는 복제된 이슈의 메트릭으로 자동 채워지며 GitLab Ultimate에서 사용할 수 있습니다:

1. GitLab 프로젝트 또는 그룹에서 **분석** > **분석 대시보드**로 이동합니다
1. **가치 흐름 대시보드**를 클릭합니다
1. 이슈가 생성됨, 이슈가 닫힘, 리드 타임 및 주기 시간을 포함한 메트릭이 표시됩니다

### 가치 흐름 분석(설정 필요 - Premium 및 Ultimate) {#value-stream-analytics-requires-setup---premium-and-ultimate}

더 자세한 분석 및 사용자 지정 가치 흐름(GitLab Premium 및 GitLab Ultimate에서 사용 가능):

1. GitLab 프로젝트 또는 그룹에서 **분석** > **가치 흐름 분석**으로 이동합니다
1. **새 가치 흐름**을 클릭하여 사용자 지정 가치 흐름을 생성합니다
1. 개발 프로세스에 따라 스테이지 및 워크플로우를 구성합니다
1. 리드 타임 및 새 이슈 카운트와 같은 메트릭이 자동으로 생성되어 생성한 스테이지 옆에 표시됩니다
1. 자세한 설정 지침은 [GitLab 가치 흐름 분석 설명서](../../user/group/value_stream_analytics/_index.md#create-a-value-stream)를 참고하세요

## 다중 프로젝트 고려사항 {#multi-project-considerations}

단일 자동화 규칙 세트를 사용하여 여러 Jira 프로젝트에서 이슈를 복제하려면 프로젝트 접두사 방법 대신 타임스탬프 기반 접근 방식을 사용하여 고유한 이슈 ID를 생성하는 것을 고려합니다:

사용자 지정 데이터에서 `iid` 값을 다음으로 바꿉니다:

```json
"iid": {{issue.created.replace("-","").replace("T","").replace(":","").replace(".","").replace("+","")}}
```

이는 생성 타임스탬프(형식: `2025-02-15T09:45:32.7+0000`)를 숫자 값으로 변환합니다. 이 접근 방식은 매우 긴 이슈 ID를 초래할 수 있으며, 두 이슈가 정확히 같은 시간에 생성되는 경우 충돌의 작은 위험이 있습니다.

## 리소스 {#resources}

- [GitLab 가치 흐름 분석](../../user/group/value_stream_analytics/_index.md)
  - [가치 흐름 생성](../../user/group/value_stream_analytics/_index.md#create-a-value-stream)
- [GitLab 가치 흐름 대시보드](../../user/analytics/value_streams_dashboard.md)
- [GitLab 이슈 API](../../api/issues.md)
  - [새 이슈 생성](../../api/issues.md#create-an-issue)
  - [이슈 편집](../../api/issues.md#update-an-issue)
- [GitLab 프로젝트 액세스 토큰](../../user/project/settings/project_access_tokens.md)
- [웹 요청을 사용한 Jira 자동화](https://community.atlassian.com/t5/Jira-articles/Automation-for-Jira-Send-web-request-using-Jira-REST-API/ba-p/1443828)
