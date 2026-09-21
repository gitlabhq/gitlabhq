---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 보안 대시보드
description: "보안 대시보드, 취약성 트렌드, 프로젝트 등급 및 메트릭."
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 고급 검색 기능을 포함한 새로운 대시보드가 `project_security_dashboard_new` 및 `group_security_dashboard_new`라는 [기능 플래그](../../../administration/feature_flags/_index.md)로 GitLab 18.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/570504)되었습니다. 플래그는 기본적으로 사용 중지되어 있습니다.
- 고급 검색 기능을 포함한 새로운 대시보드가 GitLab 18.7에서 [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에 사용으로 설정](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215574)되었습니다.
- 고급 검색 기능을 포함한 새로운 대시보드는 GitLab 18.8에서 [일반 공급](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107661)되었습니다. `project_security_dashboard_new` 및 `group_security_dashboard_new` 기능 플래그가 제거되었습니다.

{{< /history >}}

GitLab 18.6에서 [고급 취약성 관리](../vulnerability_report/_index.md#advanced-vulnerability-management)를 사용하는 개선된 보안 대시보드 버전이 도입되었습니다.

새로운 대시보드는 GitLab.com 및 GitLab Dedicated에서 기본적으로 사용으로 설정됩니다. GitLab Self-Managed 사용자는 새로운 대시보드에 액세스하려면 고급 취약성 관리를 사용으로 설정해야 합니다.

조직에서 고급 취약성 관리를 사용으로 설정하지 않았다면 [레거시 보안 대시보드](#legacy-security-dashboards)를 참조하세요.

## 보안 대시보드 {#security-dashboards}

{{< history >}}

- [고급 취약성 관리](../vulnerability_report/_index.md#advanced-vulnerability-management)를 사용하는 새로운 대시보드가 `project_security_dashboard_new` 및 `group_security_dashboard_new`라는 [기능 플래그](../../../administration/feature_flags/_index.md)로 GitLab 18.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/570504)되었습니다. 플래그는 기본적으로 사용 중지되어 있습니다.
- 새로운 대시보드가 GitLab 18.7에서 [GitLab Self-Managed 및 GitLab Dedicated에 사용으로 설정](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215574)되었습니다.
- 새로운 대시보드가 GitLab 18.8에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107661)되었습니다. `project_security_dashboard_new` 및 `group_security_dashboard_new` 기능 플래그가 제거되었습니다.

{{< /history >}}

보안 대시보드를 사용하여 애플리케이션의 보안 상태를 평가합니다. GitLab에서는 프로젝트에서 실행하는 [보안 검사기](../detect/_index.md)에서 탐지한 취약성에 대한 메트릭, 등급 및 차트의 모음을 제공합니다. 보안 대시보드는 다음 데이터를 제공합니다.

- 그룹의 모든 프로젝트에 대해 30, 60, 또는 90일 기간의 취약성 트렌드.
- 심각도별로 정렬된 미해결 취약성의 총 개수.
- 프로젝트 간 취약성 위험을 비교하기 위한 총 위험 점수.

### 사전 요구 사항 {#prerequisites}

프로젝트 또는 그룹의 보안 대시보드를 보려면 다음이 필요합니다.

- 그룹 또는 프로젝트에 대한 개발자 역할 이상.
- 프로젝트에 최소 한 개의 [보안 스캐너](../detect/_index.md)가 구성되었습니다.
- 프로젝트의 [기본 브랜치](../../project/repository/branches/default.md)에서 수행된 성공적인 보안 검사.
- 프로젝트에서 탐지된 최소 하나의 취약성.
- [고급 검색](../../search/advanced_search.md)을 포함한 [고급 취약성 관리](../vulnerability_report/_index.md#advanced-vulnerability-management)가 사용으로 설정되었습니다.

> [!note]
> 보안 대시보드는 [기본 브랜치](../../project/repository/branches/default.md)의 가장 최근에 완료된 파이프라인에서 검사 결과를 표시합니다. 대시보드는 기본 브랜치에서 실행된 완료된 파이프라인의 결과로 업데이트됩니다. 다른 병합되지 않은 브랜치의 파이프라인에서 감지된 취약성은 포함되지 않습니다.

### 보안 대시보드 보기 {#viewing-the-security-dashboard}

보안 대시보드는 기본 브랜치에서 탐지된 취약성의 데이터로 작성된 필터 가능한 차트와 패널을 표시합니다. 차트와 패널에는 미해결(분류 필요 또는 확인됨 상태) 취약성만 포함하고 더 이상 탐지되지 않는 취약성은 제외됩니다.

프로젝트 또는 그룹에 대한 보안 대시보드를 볼 수 있습니다. 각 대시보드는 보안 상태에 대한 고유한 관점을 제공합니다.

두 대시보드 모두 다음을 포함합니다.

- [차트](#charts)
  - [시간에 따른 취약성](#vulnerabilities-over-time)
  - [취약성 심각도 패널](#vulnerability-severity-panel)
  - [위험 점수](#risk-score-panel)
  - [기간에 따른 취약성](#vulnerabilities-by-age)
  - [톱 10 CWE](#top-10-cwes)
  - [SAST 분류 및 수정 퍼넬](#sast-triage-and-remediation-funnel)
- [전체 대시보드 필터링](#filter-the-entire-dashboard)
- [PDF로 내보내기](#export-as-pdf)

보안 대시보드를 보려면 다음을 수행합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **안전함** > **보안 대시보드**를 선택합니다.

### 프로젝트 보안 대시보드 {#project-security-dashboard}

프로젝트 보안 대시보드는 프로젝트의 기본 브랜치에서 탐지된 취약성을 표시합니다. 다음을 포함합니다.

- [**시간에 따른 취약성**](#vulnerabilities-over-time) 차트는 최대 90일의 기록을 포함합니다.
- [**Severity panels**](#vulnerability-severity-panel), 심각도별로 미해결 취약성을 표시합니다.
- [**위험 점수**](#risk-score-panel) 패널, 프로젝트의 전반적인 보안 위험을 표시합니다.
- [**기간에 따른 취약성**](#vulnerabilities-by-age) 차트는 경과 시간별 버킷으로 미해결 취약성을 그룹화합니다.
- [**톱 10 CWE**](#top-10-cwes) 차트, 가장 일반적인 10개의 CWE를 표시합니다.
- [**SAST 분류 및 수정 퍼넬**](#sast-triage-and-remediation-funnel) 차트는 중요하고 높은 수준의 SAST 취약성이 탐지에서 수정까지 어떻게 진행되는지 표시하며, GitLab Duo에서 처리한 스테이지를 포함합니다.

미해결 취약성은 분류 필요 또는 확인됨 상태의 취약성입니다. 거부됨 또는 해결됨 상태의 닫힌 취약성은 이 차트에 포함되지 않습니다.

![프로젝트 보안 대시보드](img/project_security_dashboard_v18_5.png)

### 그룹 보안 대시보드 {#group-security-dashboard}

그룹 보안 대시보드는 그룹 및 해당 하위 그룹의 모든 프로젝트의 기본 브랜치에서 발견된 취약성의 개요를 제공합니다. 그룹 보안 대시보드는 다음을 제공합니다.

- [**시간에 따른 취약성**](#vulnerabilities-over-time) 차트는 최대 90일의 기록을 포함합니다.
- [**Severity panels**](#vulnerability-severity-panel), 심각도별로 미해결 취약성을 표시합니다.
- [**위험 점수**](#risk-score-panel) 패널, 각 프로젝트의 총 위험 및 위험을 표시합니다.
- [**기간에 따른 취약성**](#vulnerabilities-by-age) 차트는 경과 시간별 버킷으로 미해결 취약성을 그룹화합니다.
- [**톱 10 CWE**](#top-10-cwes) 차트, 가장 일반적인 10개의 CWE를 표시합니다.
- [**SAST 분류 및 수정 퍼넬**](#sast-triage-and-remediation-funnel) 차트는 중요하고 높은 수준의 SAST 취약성이 탐지에서 수정까지 어떻게 진행되는지 표시하며, GitLab Duo에서 처리한 스테이지를 포함합니다.

### 차트 {#charts}

보안 대시보드에는 프로젝트 및 그룹의 취약성을 이해하고 대응하는 데 도움이 되는 여러 차트가 포함되어 있습니다.

#### 시간에 따른 취약성 {#vulnerabilities-over-time}

**시간에 따른 취약성** 차트는 프로젝트 및 그룹 대시보드 모두에서 사용 가능합니다. 30, 60, 또는 90일 기간의 미해결 취약성 트렌드를 표시합니다. 기본 범위는 30일입니다. GitLab은 취약성 데이터를 365일 동안 유지합니다.

차트를 사용하여 취약성이 언제 도입되었으며 시간이 지남에 따라 어떻게 변하는지 확인합니다.

세부 정보를 보려면 다음을 수행합니다.

1. 데이터 포인트 위에 마우스를 올려 그날의 취약성 개수를 확인합니다.
1. **time frame selector**를 사용하여 30, 60, 또는 90일 사이를 전환합니다.
1. 범위 핸들({{< icon name="scroll-handle" >}})을 드래그하여 특정 기간을 확대합니다.
1. **심각도**(예: **치명적**, **높음**, **중간**)로 필터링하려면 드롭다운을 사용하세요.
1. 다음 옵션 중 하나로 데이터를 그룹화하려면 버튼을 사용합니다.
   - **심각도**: 심각함, 높음, 중간, 낮음, 정보 및 알 수 없음.
   - **보고서 유형**: SAST, DAST 및 종속성 검사 등.
1. 90일을 초과하지만 지난 365일 이내의 데이터를 탐색하려면 [`SecurityMetrics.vulnerabilitiesOverTime` GraphQL API](../../../api/graphql/reference/_index.md#securitymetricsvulnerabilitiesovertime)를 사용합니다.

![시간에 따른 취약성](img/vulnerabilities_over_time_chart_v18_5.png)

#### 취약성 심각도 패널 {#vulnerability-severity-panel}

취약성 심각도 패널은 [심각도](../vulnerabilities/severities.md)별로 미해결 취약성의 총 개수를 표시합니다.

세부 정보를 보려면 다음을 수행합니다.

1. 심각도 패널에서 조사할 심각도를 찾습니다.
1. **보기**를 선택합니다.
   - 취약성 보고서가 열리고 해당 심각도의 취약성만 포함합니다.
   - 설정한 모든 페이지 수준 필터도 적용됩니다.

![심각도 수준](img/security_dashboard_severity_panels_v18_5.png)

#### 위험 점수 패널 {#risk-score-panel}

{{< history >}}

- 그룹 대시보드의 위험 점수 패널:
  - GitLab 18.6에서 `security_dashboard_risk_score`라는 [기능 플래그](../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/570504)되었습니다. 기본적으로 사용 중지되어 있습니다.
  - GitLab 18.7에서 [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에 사용으로 설정](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215574)되었습니다.
  - GitLab 18.8에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107661)되었습니다. `security_dashboard_risk_score` 기능 플래그가 제거되었습니다.
- 프로젝트 대시보드의 위험 점수 차트:
  - GitLab 18.11에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/work_items/591112)되었습니다.

{{< /history >}}

위험 점수 패널은 그룹 또는 프로젝트의 전반적인 보안 위험을 표시합니다. 패널은 두 가지 보기를 갖습니다.

1. **묶음 없음**(기본값) 보기는 그룹의 총 위험 점수를 표시합니다.
   - 원형 게이지는 중심에 계산된 위험 점수를 표시합니다.
   - 색상 막대는 위험 수준을 나타냅니다.
     - 녹색: 낮은 위험
     - 황색: 중간 위험
     - 주황색: 높은 위험
     - 빨간색: 치명적 위험
1. **프로젝트**를 선택하여 각 프로젝트의 위험 점수를 비교합니다.
   - 각 프로젝트 타일은 프로젝트의 위험 수준에 따라 색상으로 코드화됩니다.
   - 타일 위에 마우스를 올려 프로젝트 이름 및 위험 점수를 포함한 세부 정보를 확인합니다.
   - 타일을 선택한 후 프로젝트 이름을 선택하여 해당 프로젝트의 취약성 보고서를 엽니다.

![보안 대시보드 기본 보기](img/group_security_dashboard_risk_score_v18_6.png)

![보안 대시보드 프로젝트 그리드 보기](img/group_security_dashboard_total_risk_score_project_v18_6.png)

위험 점수는 다음을 포함한 여러 요소로부터 계산됩니다.

- 취약성의 심각도
- 취약성의 경과 시간
- KEV(알려진 악용된 취약성) 상태
- EPSS(악용 예측 채점 시스템) 점수

#### 기간에 따른 취약성 {#vulnerabilities-by-age}

{{< history >}}

- 프로젝트 대시보드의 기간에 따른 취약성 차트:
  - GitLab 18.11에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/work_items/590979)되었습니다.

{{< /history >}}

**기간에 따른 취약성** 차트는 그룹 및 프로젝트 대시보드에서 사용 가능합니다. 처음 탐지된 후부터 경과 시간을 기반으로 미해결 취약성의 분포를 표시합니다. 심각도별 또는 보고서 유형별로 취약성을 그룹화할 수 있으므로 수정 작업이 필요한 곳을 파악하는 데 도움이 됩니다.

세부 정보를 보려면 다음을 수행합니다.

1. 데이터 포인트 위에 마우스를 올려 해당 경과 시간 그룹화의 취약성 개수를 확인합니다.
1. **심각도**(예: **치명적**, **높음**, **중간**)로 필터링하려면 드롭다운 목록을 사용합니다.
1. 다음 옵션 중 하나로 데이터를 그룹화하려면 버튼을 사용합니다.
   - **심각도**: 심각함, 높음, 중간, 낮음, 정보 및 알 수 없음.
   - **보고서 유형**: SAST, DAST 및 종속성 검사 등.

![기간에 따른 취약성](img/vulnerabilities_by_age_chart_v18_9.png)

#### 톱 10 CWE {#top-10-cwes}

{{< history >}}

- GitLab 18.11에서 `new_security_dashboard_vulnerabilities_by_identifier`라는 [기능 플래그](../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/17422)되었습니다. 기본적으로 사용으로 설정되어 있습니다.
- GitLab 19.0에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/592130)되었습니다. `new_security_dashboard_vulnerabilities_by_identifier` 기능 플래그가 제거되었습니다.

{{< /history >}}

**톱 10 CWE** 차트는 그룹 및 프로젝트 대시보드에서 사용 가능합니다. 그룹 또는 프로젝트의 미해결 취약성과 관련된 가장 일반적인 10개의 CWE 식별자를 표시합니다.

세부 정보를 보려면 다음을 수행합니다.

1. 데이터 포인트 위에 마우스를 올려 각 CWE 유형의 취약성 총 개수를 확인합니다.
1. **심각도**(예: **치명적**, **중간** 또는 **높음**)로 필터링하려면 드롭다운 목록을 사용합니다.

![톱 10 CWE](img/group_security_dashboard_top_10_cwes_v18_11.png)

#### SAST 분류 및 수정 퍼넬 {#sast-triage-and-remediation-funnel}

{{< history >}}

- GitLab 19.3에서 `security_dashboard_agentic_adoption`이라는 [기능 플래그](../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239423)되었습니다. 기본적으로 사용으로 설정되어 있습니다.

{{< /history >}}

**SAST 분류 및 수정 퍼넬** 차트는 그룹 및 프로젝트 대시보드에서 사용 가능합니다. 중요하고 높은 수준의 SAST 취약성이 30, 60, 또는 90일 기간의 분류 및 수정을 통해 어떻게 진행되는지 표시합니다. 기본 범위는 30일입니다.

퍼넬은 최대 4개의 스테이지를 갖습니다. 각 스테이지는 도달한 취약성의 개수를 표시합니다.

- **심각 및 높음 SAST 취약성**: SAST에서 탐지한 취약성입니다.
- **정탐**: [SAST 오탐 탐지](../vulnerabilities/false_positive_detection.md)에서 정탐으로 확인된 취약성입니다.
- **AI가 만든 MR(병합 요청)에 취약성**: [에이전틱 SAST 취약성 해결](../vulnerabilities/agentic_vulnerability_resolution.md)에서 만든 병합 요청에 취약성입니다.
- **수정된 취약성**: 병합된 AI가 만든 병합 요청에 의해 수정된 취약성입니다.

시간 범위 선택기를 사용하여 퍼넬을 30, 60, 또는 90일 사이로 전환합니다.

![SAST 분류 및 수정 퍼넬](img/sast_triage_and_remediation_funnel_v19_3.png)

마지막 3개의 스테이지는 GitLab Duo를 사용합니다. 이러한 스테이지를 채우려면 다음을 수행합니다.

- 그룹 및 프로젝트에 대해 GitLab Duo를 켭니다.
- [SAST 오탐 탐지](../vulnerabilities/false_positive_detection.md)를 구성합니다.
- [에이전식 SAST 취약성 해결](../vulnerabilities/agentic_vulnerability_resolution.md)을 구성합니다.

이러한 기능 중 하나가 비활성화되면 퍼넬은 영향받은 스테이지를 어떤 기능을 활성화해야 하는지 설명하는 메시지로 대체합니다. 메시지는 프로젝트 및 그룹 대시보드에 따라 다르며, 사용할 수 없는 기능에 따라 달라집니다.

![기능이 비활성화된 SAST 분류 및 수정 퍼넬](img/sast_triage_and_remediation_funnel_empty_state_v19_3.png)

### 전체 대시보드 필터링 {#filter-the-entire-dashboard}

두 가지 수준에서 결과를 필터링할 수 있습니다.

- **대시보드 필터**: 전체 대시보드에 적용됩니다. 이러한 필터를 사용하면 모든 차트가 업데이트됩니다.
- **Chart and panel filters**: 보고 있는 차트 또는 패널에만 적용됩니다.

사용 가능한 대시보드 필터에는 다음이 포함됩니다.

- **보고서 유형**: SAST, DAST, 종속성 검사 등을 포함하여 검사기로 필터링합니다.
- **프로젝트**: 결과를 특정 프로젝트로 제한합니다. 그룹 보안 대시보드에서만 사용 가능합니다.

그룹 보안 대시보드에서는 다음을 기준으로도 필터링할 수 있습니다.

- **보안 속성**: 프로젝트에 적용된 보안 특성으로 필터링하며 비즈니스 영향, 애플리케이션, 사업 단위, 인터넷 위험 노출 및 위치에 대한 범주를 포함합니다. 이러한 필터는 포함 관계(**다음 중 하나** 연산자 사용)이거나 배제(**다음 중 하나가 아닙니다** 연산자 사용)일 수 있습니다. 보안 속성을 구성하고 프로젝트에 적용하려면 [보안 속성](../attributes/_index.md)을 참조하세요.

대시보드 필터 동작:

- 필터는 모든 대시보드 차트 및 패널에 즉시 적용됩니다.
- 적용한 필터는 세션 동안 계속 적용되며, 제거하지 않는 한 제거되지 않습니다.
- 대시보드에서 취약성 보고서를 열면 활성 필터가 취약성 보고서에 자동으로 적용됩니다.

전체 대시보드에 필터를 적용하려면 다음을 수행합니다.

1. 대시보드 상단의 필터 표시줄에서 **Filter results...**을 선택합니다.
1. 드롭다운 목록에서 필터 유형을 선택합니다.
1. 하나 이상의 필터 값을 선택합니다.

### PDF로 내보내기 {#export-as-pdf}

{{< history >}}

- GitLab 18.10에서 `new_security_dashboard_pdf_export`라는 [기능 플래그](../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224664)되었습니다. 기본적으로 사용 중지되어 있습니다.
- GitLab 18.11에서 [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에 사용으로 설정](https://gitlab.com/gitlab-org/gitlab/-/issues/589201)되었습니다.
- GitLab 19.0에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/589201)되었습니다. `new_security_dashboard_pdf_export` 기능 플래그가 제거되었습니다.

{{< /history >}}

보안 대시보드를 보고서 및 프레젠테이션에 사용하기 위해 PDF로 내보낼 수 있습니다. 내보내기는 활성 필터를 포함하여 대시보드의 모든 차트 및 패널의 현재 상태를 캡처합니다.

대시보드를 PDF로 내보내려면 다음을 수행합니다.

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **안전함** > **보안 대시보드**를 선택합니다.
1. 선택 사항입니다. 내보내기에 포함할 데이터를 사용자 지정하려면 필터를 적용합니다.
1. **PDF로 내보내기**를 선택합니다.

## 레거시 보안 대시보드 {#legacy-security-dashboards}

{{< details >}}

- 제공 서비스: GitLab Self-Managed

{{< /details >}}

고급 취약성 관리를 사용으로 설정하지 않은 GitLab Self-Managed 고객은 최신 보안 대시보드에 액세스할 수 없습니다. 이 경우 레거시 보안 대시보드에 여전히 액세스할 수 있습니다.

보안 대시보드는 애플리케이션의 보안 상태를 평가하는 데 사용됩니다. GitLab에서는 프로젝트에서 실행하는 [보안 검사기](../detect/_index.md)에서 탐지한 취약성에 대한 메트릭, 등급 및 차트의 모음을 제공합니다. 보안 대시보드는 다음과 같은 데이터를 제공합니다.

- 그룹의 모든 프로젝트에 대해 30, 60, 또는 90일 기간의 취약성 트렌드
- 취약성 심각도를 기반으로 한 각 프로젝트의 등급 평가
- 지난 365일 내에 탐지된 취약성의 총 수(심각도 포함)

보안 대시보드 데이터를 사용하여 보안 상태를 개선합니다. 예를 들어, 365일 트렌드 보기는 취약성 증가가 있었던 날을 표시합니다. 해당 날의 코드 변경 사항을 검토하여 근본 원인 분석을 수행하고 향후 취약성을 방지할 수 있는 더 나은 정책을 개발합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 개요를 보려면 [보안 대시보드 - 고급 보안 테스트](https://www.youtube.com/watch?v=Uo-pDns1OpQ)를 참조하세요.

## 레거시 대시보드의 필수 조건 {#prerequisites-for-the-legacy-dashboards}

보안 대시보드를 보려면 다음이 필요합니다.

- 그룹 또는 프로젝트의 개발자 역할이 필요합니다.
- 프로젝트에 최소 한 개의 [보안 스캐너](../detect/_index.md)가 구성되었습니다.
- 프로젝트의 [기본 브랜치](../../project/repository/branches/default.md)에서 수행된 성공적인 보안 검사.
- 프로젝트에서 탐지된 최소 1개의 취약성입니다.

> [!note]
> 보안 대시보드는 [기본 브랜치](../../project/repository/branches/default.md)의 가장 최근에 완료된 파이프라인에서 검사 결과를 표시합니다. 대시보드는 기본 브랜치에서 실행된 완료된 파이프라인의 결과로 업데이트됩니다. 다른 병합되지 않은 브랜치의 파이프라인에서 감지된 취약성은 포함되지 않습니다.

## 레거시 보안 대시보드 보기 {#viewing-the-legacy-security-dashboard}

보안 대시보드는 프로젝트, 그룹 및 보안 센터 수준에서 볼 수 있습니다. 각 대시보드는 보안 상태에 대한 고유한 관점을 제공합니다.

### 프로젝트 보안 대시보드 {#project-security-dashboard-1}

프로젝트 보안 대시보드는 지정된 프로젝트에 대해 최대 365일의 기록 데이터를 포함하여 시간에 따른 탐지된 취약성의 총 수를 표시합니다. 대시보드는 기본 브랜치의 미해결 취약성의 기록 보기입니다. 미해결 취약성은 `Needs triage` 또는 `Confirmed` 상태만 해당하며(`Dismissed` 또는 `Resolved` 취약성은 제외됨).

프로젝트의 보안 대시보드를 보려면 다음을 수행합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **안전함** > **보안 대시보드**를 선택합니다.
1. 필요한 것을 필터링하고 검색합니다.
   - 차트를 심각도별로 필터링하려면 범례 이름을 선택합니다.
   - 특정 시간 범위를 보려면 시간 범위 핸들({{< icon name="scroll-handle" >}})을 사용합니다.
   - 차트의 특정 영역을 보려면 맨 왼쪽 아이콘({{< icon name="marquee-selection" >}})을 선택하고 차트 전체를 드래그합니다.
   - 원래 범위로 재설정하려면 **Remove Selection**({{< icon name="redo" >}})를 선택합니다.

![프로젝트 보안 대시보드](img/project_security_dashboard_v16_6.png)

#### 취약성 차트 다운로드 {#downloading-the-vulnerability-chart}

프로젝트 보안 대시보드에서 취약성 차트의 이미지를 다운로드하여 설명서, 프레젠테이션 등에 사용할 수 있습니다. 취약성 차트의 이미지를 다운로드하려면 다음을 수행합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **안전함** > **보안 대시보드**를 선택합니다.
1. **Save chart as an image**({{< icon name="download" >}})을 선택합니다.

SVG 형식으로 이미지를 다운로드하라는 메시지가 표시됩니다.

### 그룹 보안 대시보드 {#group-security-dashboard-1}

그룹 보안 대시보드는 그룹 및 해당 하위 그룹의 모든 프로젝트의 기본 브랜치에서 발견된 취약성의 개요를 제공합니다. 그룹 보안 대시보드는 다음을 제공합니다.

- 30, 60, 또는 90일 기간의 취약성 트렌드
- 그룹의 각 프로젝트에 대한 등급, 가장 높은 심각도의 미해결 취약성에 따라 할당됨. 등급은 다음 기준을 사용하여 할당됩니다.

| 등급 | 설명                                     |
| ----- | ----------------------------------------------- |
| **금** | 하나 이상의 `critical` 취약성          |
| **D** | 하나 이상의 `high` 또는 `unknown` 취약성 |
| **C** | 하나 이상의 `medium` 취약성            |
| **B** | 하나 이상의 `low` 취약성               |
| **A** | 취약성 없음                            |

그룹 보안 대시보드를 보려면 다음을 수행합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 대시보드**를 선택합니다.
1. **시간에 따른 취약성** 차트 위에 마우스를 올려 취약성에 대한 자세한 정보를 확인합니다.
   - 30, 60, 또는 90일 기간의 취약성 트렌드를 표시할 수 있습니다(기본값은 90일).
   - 90일을 초과하는 데이터를 집계하여 보려면 [`VulnerabilitiesCountByDay` GraphQL API](../../../api/graphql/reference/_index.md#vulnerabilitiescountbyday)를 사용합니다. GitLab은 365일 동안 데이터를 유지합니다.

1. **프로젝트 보안 상태** 섹션 아래의 화살표를 선택하여 특정 등급 평가에 속하는 프로젝트를 확인합니다.
   - 프로젝트에서 발견된 특정 심각도의 취약성 개수를 확인할 수 있습니다.
   - 프로젝트의 보안 대시보드에 직접 액세스하려면 프로젝트 이름을 선택할 수 있습니다.

![그룹 보안 대시보드](img/group_security_dashboard_v16_6.png)

## 가치 흐름 대시보드의 취약성 메트릭 {#vulnerability-metrics-in-the-value-streams-dashboard}

[가치 스트림 대시보드](../../analytics/value_streams_dashboard.md) 비교 패널에는 추가 취약성 메트릭을 사용할 수 있으며 조직의 소프트웨어 제공 워크플로우의 컨텍스트에서 보안 노출을 이해하는 데 도움이 됩니다.

## 관련 항목 {#related-topics}

- [보안 센터](../security_center/_index.md)
- [취약성 보고서](../vulnerability_report/_index.md)
- [취약성 페이지](../vulnerabilities/_index.md)
- [취약성 자동 해결](../policies/vulnerability_management_policy.md)
