---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "GitLab 보안 지표 및 KPI 솔루션 배포 가이드이며, 취약성 데이터를 Splunk로 내보내기, CI/CD 파이프라인 설정, 대시보드 구성 및 모범 사례를 포함합니다."
title: 보안 지표 및 KPI
---

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 문서는 GitLab 보안 지표 및 KPI 솔루션 구성 요소의 설치, 구성 및 사용자 가이드를 설명합니다. 이 보안 솔루션 구성 요소는 비즈니스 단위, 시간 범위, 취약성 심각도 및 보안 유형으로 볼 수 있는 지표 및 KPI를 제공합니다. 월간 또는 분기별로 PDF 문서를 포함하여 보안 태세의 스냅샷을 제공할 수 있습니다. 데이터는 Splunk의 대시보드를 사용하여 시각화됩니다.

![보안 지표 및 KPI](img/security_metrics_kpi_v17_9.png)

이 솔루션은 GraphQL API를 사용하여 GitLab 프로젝트 또는 그룹에서 취약성 데이터를 내보내고, HTTP 이벤트 수집기(HEC)를 통해 Splunk로 전송하며, 보안 지표 시각화를 위한 기본 제공 대시보드를 포함합니다. 내보내기 프로세스는 GitLab CI/CD 파이프라인으로 일정에 따라 실행되도록 설계되었습니다.

## 시작하기 {#getting-started}

### 솔루션 구성 요소 다운로드 {#download-the-solution-component}

1. 계정 팀으로부터 초대 코드를 입수합니다.
1. 초대 코드를 사용하여 [솔루션 구성 요소 웹스토어](https://cloud.gitlab-accelerator-marketplace.com)에서 솔루션 구성 요소를 다운로드합니다.

### 솔루션 구성 요소 프로젝트 설정 {#set-up-the-solution-component-project}

1. 이 내보내기 도구를 호스팅할 새로운 GitLab 프로젝트를 만듭니다.
1. 제공된 파일을 프로젝트에 복사합니다:
   - `export_vulns.py`
   - `send_to_splunk.py`
   - `requirements.txt`
   - `.gitlab-ci.yml`
1. 프로젝트 설정에서 필요한 CI/CD 변수를 구성합니다.
1. 파이프라인 일정을 설정합니다(예: 매일 또는 매주).

## 작동 방식 {#how-it-works}

솔루션은 두 가지 주요 구성 요소로 구성됩니다:

1. GitLab 보안 대시보드에서 데이터를 가져오는 취약성 내보내기 도구
1. 내보낸 데이터를 처리하고 Splunk HEC로 전송하는 Splunk 수집 도구

파이프라인은 두 스테이지로 실행됩니다:

1. `extract`: 취약성을 가져와서 CSV에 저장합니다
1. `ingest`: 취약성 데이터를 Splunk로 전송합니다

## 구성 {#configuration}

### 필요한 CI/CD 변수 {#required-cicd-variables}

| 변수 | 설명 | 예시 값 |
|----------|-------------|---------------|
| `SCOPE` | 취약성 스캔의 대상 범위 | `group:security/appsec` 또는 `security/my-project` |
| `GRAPHQL_API_TOKEN` | API 액세스 권한이 있는 GitLab 개인 액세스 토큰 | `glpat-XXXXXXXXXXXXXXXX` |
| `GRAPHQL_API_URL` | GitLab GraphQL API URL | `https://gitlab.com/api/graphql` |
| `SPLUNK_HEC_TOKEN` | Splunk HTTP 이벤트 수집기 토큰 | `11111111-2222-3333-4444-555555555555` |
| `SPLUNK_HEC_URL` | Splunk HEC 엔드포인트 URL | `https://splunk.company.com:8088/services/collector` |

### 선택적 CI/CD 변수 {#optional-cicd-variables}

| 변수 | 설명 | 예시 값 | 기본값 |
|----------|-------------|---------------|---------|
| `SEVERITY_FILTER` | 쉼표로 구분한 심각도 수준 목록 | `CRITICAL,HIGH,MEDIUM` | 모든 심각도 |
| `VULN_TIME_WINDOW` | 취약성 수집의 시간 범위 | `24h`, `7d` 또는 `all` | `24h` |

### 범위 구성 {#scope-configuration}

`SCOPE` 변수는 스캔할 프로젝트 또는 그룹을 결정합니다:

- 프로젝트의 경우: `mygroup/myproject`
- 그룹의 경우: `group:mygroup/subgroup`
- 전체 인스턴스의 경우: `instance`

### 심각도 필터 예제 {#severity-filter-examples}

유효한 심각도 수준:

- `CRITICAL`
- `HIGH`
- `MEDIUM`
- `LOW`
- `UNKNOWN`

예제 조합:

- `CRITICAL,HIGH`
- `CRITICAL,HIGH,MEDIUM`
- 모든 심각도를 포함하려면 비워 둡니다

### 시간 범위 구성 {#time-window-configuration}

`VULN_TIME_WINDOW` 변수는 취약성을 얼마나 오래 조회할 것인지 제어합니다:

- 형식: `<number><unit>` 여기서:
  - `number`: 음수가 아닌 정수
  - `unit`: 시간은 `h` 또는 날짜는 `d`
- 예:
  - `24h`: 지난 24시간
  - `7h`: 지난 7시간
  - `15d`: 지난 15일
  - `30d`: 지난 30일
  - `all`: 모든 취약성(첫 번째 실행에 유용)

기본값: `24h`

파이프라인 구성 예제:

```yaml
# For 12-hour window
variables:
  VULN_TIME_WINDOW: "12h"

# For 3-day window
variables:
  VULN_TIME_WINDOW: "3d"

# For all vulnerabilities
variables:
  VULN_TIME_WINDOW: "all"
```

선택한 시간 범위를 기반으로 파이프라인을 일정에 따라 실행합니다. 예를 들어:

- 12시간의 경우: 하루에 두 번 예약합니다
- 3일의 경우: 3일마다 예약합니다
- 취약성이 누락되지 않도록 일정 설정에서 약간의 중복을 추가합니다

## 파이프라인 설정 {#pipeline-setup}

1. **First Run**:

   - `VULN_TIME_WINDOW: "all"`로 설정하여 모든 과거 취약성을 수집합니다
   - 파이프라인을 한 번 실행합니다

1. **Ongoing Collection**:

   - `VULN_TIME_WINDOW`을 원하는 시간 범위(`24h` 또는 `7d`)로 설정합니다
   - 파이프라인 일정을 설정합니다:
     - `24h`의 경우: 매일 예약합니다
     - `7d`의 경우: 매주 예약합니다

## Splunk 통합 {#splunk-integration}

스크립트는 취약성을 Splunk로 이벤트로 전송합니다.

### 인덱스 구성 {#index-configuration}

1. Splunk에서 `gitlab_vulns` 이름의 새로운 인덱스를 만듭니다
1. HEC 토큰을 만들 때:
   - 기본 **인덱스**를 `gitlab_vulns`로 설정합니다(이 인덱스는 제공된 Splunk 대시보드의 기본 검색에서 참조됩니다)
   - 토큰이 이 인덱스에 쓸 수 있는 권한을 확보합니다
   - 토큰이 이벤트 데이터를 JSON으로 올바르게 구문 분석할 수 있는 **sourcetype**을 가지고 있는지 확인합니다

각 이벤트에는 다음이 포함됩니다:

- 감지 시간
- 취약성 제목 및 설명
- 심각도 수준
- 스캐너 정보
- 프로젝트 세부 사항
- 프로젝트 및 취약성에 대한 URL

## 대시보드 설정 {#dashboard-setup}

제공된 대시보드는 GitLab 취약성 데이터에 대한 포괄적인 가시성을 제공하며 다음과 같은 시각화를 포함합니다:

- 심각 및 높음 취약성에 대한 P95 나이 지표(방사형 게이지)
- 나이 범위(0-30일, 31-90일, 91-180일, 180일 이상)에 걸친 심각 및 높음 취약성의 분포를 보여주는 노화 분석
- 발생 수가 가장 많은 상위 10개 CVE
- 프로젝트 경로 및 심각도별 취약성 분포
- 모든 지표는 비즈니스 단위 및 시간 범위로 필터링할 수 있습니다

대시보드를 설정하려면:

1. **Business Unit Mapping**:
   1. 두 개의 열이 있는 CSV 파일을 만듭니다:

      ```shell
      project_url,business_unit
      ```

   1. 각 GitLab 프로젝트 URL을 해당 비즈니스 단위에 매핑합니다.
   1. 파일을 Splunk에 조회 테이블로 업로드합니다:
      1. **설정** > **Lookups** > **Lookup table files**로 이동합니다.
      1. **New Lookup Table File**을 선택합니다.
      1. CSV 파일을 업로드합니다.
      1. **Destination filename**을 `business_unit_mapping.csv`로 설정합니다.
      1. 권한을 구성합니다:
         1. `<splunk_dir>/etc/apps/search/lookups/business_unit_mapping.csv`로 표시된 행을 찾습니다.
         1. **권한**을 선택합니다.
         1. 권한을 다음 중 하나로 설정합니다:
            - **전역**로 설정하여 인스턴스 전체 액세스 권한을 부여합니다.
            - 필요에 따라 특정 앱 또는 역할과 공유합니다.
         1. **저장**을 선택합니다.

1. **Dashboard Installation**:
   1. 제공된 `vuln_metrics_dashboard.xml` 파일을 저장합니다.
   1. Splunk에서:
      1. 검색 앱으로 이동합니다.
      1. **대시보드** > **Create New Dashboard**를 클릭합니다.
      1. **소스**를 편집 보기에서 선택합니다.
      1. 기본 XML을 `vuln_metrics_dashboard.xml`의 내용으로 바꿉니다.
      1. 대시보드를 저장합니다.

## 출력 형식 {#output-format}

중간 CSV 파일에는 다음이 포함됩니다:

- `detectedAt`: 감지 타임스탬프
- `title`: 취약성 제목
- `severity`: 심각도 수준
- `primaryIdentifier`: 취약성 식별자
- `exporter`: 스캐너 이름
- `projectPath`: GitLab 프로젝트 경로
- `projectUrl`: 프로젝트 URL
- `description`: 취약성 설명
- `webUrl`: 취약성 세부 정보 URL

## 오류 처리 {#error-handling}

솔루션은 다음을 포함합니다:

- 지수 백오프를 사용한 속도 제한 처리
- Splunk 수집을 위한 배치 처리
- 적절한 오류 보고
- 시간 초과 처리
- UTF-8 인코딩 지원

## 모범 사례 {#best-practices}

1. **Token Permissions**:

   - GRAPHQL_API_TOKEN이 필요합니다:
     - 대상 그룹/프로젝트에 대한 읽기 액세스 권한
     - 보안 대시보드 액세스
   - SPLUNK_HEC_TOKEN이 필요합니다:
     - 대상 인덱스에 대한 이벤트 제출 권한

1. **Schedule Frequency**:

   - 일정을 `VULN_TIME_WINDOW`과 일치하도록 설정합니다
   - 취약성 누락을 방지하기 위해 중복을 포함합니다
   - 조직의 SLA를 고려합니다

1. **모니터링**:

   - 파이프라인 성공/실패 모니터링
   - 내보낸 취약성 개수 추적
   - Splunk 수집 성공 모니터링

## 문제 해결 {#troubleshooting}

일반적인 문제 및 해결책:

1. **No vulnerabilities exported**:

   - SCOPE 설정 확인
   - 토큰 권한 확인
   - 보안 대시보드 액세스 확인

1. **Splunk ingestion fails**:

   - HEC URL 및 토큰 확인
   - 네트워크 연결 확인
   - 인덱스 권한 확인
