---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 분석
description: 취약성 분석 및 평가.
---

분석은 취약성 관리 수명 주기의 세 번째 단계입니다: 탐지, 분류, 분석, 수정.

분석은 취약성의 세부 정보를 평가하여 수정할 수 있는지, 해야 하는지를 결정하는 프로세스입니다. 취약성을 일괄 분류할 수 있지만 분석은 개별적으로 수행해야 합니다. 위험 관리 프레임워크의 일부로서 분석은 리소스가 가장 효과적인 곳에 적용되도록 보장합니다. 보안 대시보드 및 취약성 보고서에 포함된 데이터를 사용하여 취약성의 심각도 및 관련 위험에 따라 취약성 분석을 우선 순위 지정합니다.

## 범위 {#scope}

분석 단계의 범위는 분류 단계를 거쳐 확인된 모든 취약성으로서 추가 조치가 필요한 것들입니다.

취약성 보고서를 필터링하여 분석이 필요한 취약성을 식별합니다:

- **상태**: 확인됨

## 위험 분석 {#risk-analysis}

위험 평가 프레임워크에 따라 취약성 분석을 수행해야 합니다. 이미 위험 평가 프레임워크를 사용 중이 아니라면 다음을 검토하세요:

- [SANS Institute Vulnerability Management Framework](https://www.sans.org/blog/the-vulnerability-assessment-framework/)
- [OWASP Threat and Safeguard Matrix (TaSM)](https://owasp.org/www-project-threat-and-safeguard-matrix/)

가능하면 [Security Analyst 에이전트](../../duo_agent_platform/agents/foundational_agents/security_analyst_agent.md)를 사용하여 취약성 분석을 가속화합니다. 에이전트는 통찰력, 위험 평가, 수정 지침을 제공하여 보안 발견 사항을 효율적으로 분류, 평가, 수정합니다.

취약성의 위험 점수 계산은 조직에 따라 달라지는 기준에 따라 다릅니다. 기본 위험 점수 공식은 다음과 같습니다:

위험 = 가능성 x 영향

가능성 및 영향 수치는 취약성 및 환경에 따라 다릅니다. 이러한 수치를 결정하고 위험 점수를 계산하려면 GitLab에서 사용할 수 없는 일부 정보가 필요할 수 있습니다. 대신 위험 관리 프레임워크에 따라 이를 계산해야 합니다. 계산한 후 취약성에 대해 제기한 이슈에 기록합니다.

일반적으로 취약성에 소요되는 시간과 노력은 그 위험에 비례해야 합니다. 예를 들어 중대 및 높은 위험의 취약성만 분석하고 나머지는 해지하도록 선택할 수 있습니다. 취약성에 대한 위험 임계값에 따라 이 결정을 내려야 합니다.

## 분석 전략 {#analysis-strategies}

이 전략들을 시도하여 가장 중요한 취약성에 먼저 집중합니다.

### 최고 심각도의 취약성 우선 순위 지정 {#prioritize-vulnerabilities-of-highest-severity}

최고 심각도의 취약성을 식별하는 데 도움이 되도록:

- 분류 단계에서 아직 수행하지 않았으면 [Vulnerability Prioritizer CI/CD 구성 요소](../vulnerabilities/risk_assessment_data.md#vulnerability-prioritizer)를 사용하여 분석할 취약성의 우선 순위를 지정합니다.
- 각 그룹에 대해 취약성 보고서를 필터링하여 분석이 필요한 취약성의 우선 순위를 지정합니다:

  - **상태**: 확인됨
  - **활동**: 여전히 감지됨
  - **그룹 기준**: 심각도
- 최고 위험 프로젝트(예: 고객에게 배포된 애플리케이션)의 취약성 분석의 우선 순위를 지정합니다.

### 해결 방법이 제공되는 취약성의 우선 순위 지정 {#prioritize-vulnerabilities-that-have-a-solution-available}

일부 취약성에는 해결 방법이 있습니다. 예를 들어 "13.2 버전에서 13.8로 업그레이드"합니다. 이는 이러한 취약성을 분석하고 수정하는 데 소요되는 시간을 줄입니다. 일부 해결 방법은 GitLab Duo가 활성화된 경우에만 사용 가능합니다.

취약성 보고서를 필터링하여 해결 방법이 있는 취약성을 식별합니다.

- SBOM 스캔으로 감지된 취약성의 경우 다음 기준을 사용하세요:
  - **상태**: 확인됨
  - **활동**: 해결 방법 있음
- SAST로 감지된 취약성의 경우 다음 기준을 사용하세요:
  - **상태**: 확인됨
  - **활동**: Vulnerability Resolution available

## 취약성 세부 정보 및 조치 {#vulnerability-details-and-action}

모든 취약성에는 탐지 시기, 탐지 방법, 심각도 등급, 전체 로그를 포함하는 세부 정보가 포함된 [취약성 페이지](../vulnerabilities/_index.md)가 있습니다. 이 정보를 사용하여 취약성을 분석합니다.

다음 팁들도 취약성을 분석하는 데 도움이 될 수 있습니다:

- [GitLab Duo Vulnerability Explanation](duo.md)을 사용하여 취약성을 설명하고 수정을 제안합니다. SAST로 감지된 취약성에만 사용 가능합니다.
- 타사 교육 공급업체에서 제공하는 [보안 교육](../vulnerabilities/_index.md#view-security-training-for-a-vulnerability)을 사용하여 특정 취약성의 특성을 이해합니다.

확인된 각 취약성을 분석한 후 다음 중 하나를 수행해야 합니다:

- 수정하기로 결정했으면 상태를 **확인됨**으로 유지합니다.
- 수정하지 않기로 결정했으면 상태를 **해지됨**으로 변경합니다.

취약성을 확인하는 경우:

1. [이슈 생성](../vulnerabilities/_index.md#create-a-gitlab-issue-for-a-vulnerability)하여 수정 작업을 추적, 문서화, 관리합니다.
1. 취약성 관리 수명 주기의 수정 단계로 진행합니다.

취약성을 해지하는 경우 해지한 이유를 설명하는 간단한 의견을 제공해야 합니다. 해지된 취약성은 다시 감지되어도 무시됩니다. 취약성 레코드는 감사 목적으로 유지됩니다(보관될 때까지). 필요에 따라 상태를 업데이트하여 수명 주기를 관리할 수 있습니다.
