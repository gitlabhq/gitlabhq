---
stage: AI Clients
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 보안 취약성을 분석하고 비즈니스 영향을 기반으로 수정을 우선순위화합니다.
title: 보안 취약성 분석 및 수정 우선순위화
---

여러 보안 취약성을 평가하고 즉시 주의가 필요한 것들을 파악해야 할 때는 다음 지침을 따릅니다.

- 예상 소요 시간: 15~25분
- 수준: 중급
- 사전 요구 사항: GitLab Duo Enterprise 추가 기능, 취약성 보고서에서 사용 가능한 취약성

## 문제 {#the-challenge}

보안 스캔은 많은 수의 취약성 경고를 생성하는 경우가 많아서 거짓 양성을 식별하고 어떤 문제가 가장 큰 비즈니스 위험을 초래하는지 파악하기 어렵습니다.

## 방법 {#the-approach}

GitLab Duo Chat, 취약성 설명 및 취약성 해결을 사용하여 취약성을 분석하고, 비즈니스 영향을 평가하고, 우선순위가 정해진 수정 계획을 만듭니다.

### 1단계:  취약성 설명 {#step-1-explain-vulnerabilities}

프로젝트의 취약성 보고서로 이동합니다. 높음 또는 심각 취약성 하나씩 취약성 설명을 사용하여 문제를 설명합니다. 그 다음 GitLab Duo Chat을 사용하여 후속 질문을 합니다.

```plaintext
Based on the earlier vulnerability explanation:

1. What specific security risk does this pose?
2. How could this be exploited in our [application_type]?
3. What data or systems could be compromised?
4. Is this a true positive or likely false positive?
5. What is the realistic business impact?

Consider our application stack: [technology_stack] and deployment environment: [environment_details].
```

예상 결과: 각 취약성의 실제 영향과 악용될 수 있는 방식에 대한 명확한 설명입니다.

### 2단계:  위험 우선순위화 {#step-2-prioritize-risks}

GitLab Duo Chat을 사용하여 여러 취약성을 함께 분석하고 우선순위 행렬을 만듭니다.

```plaintext
Based on these vulnerability explanations, help me prioritize fixes:

[paste_vulnerability_summaries]

Create a priority matrix considering:
1. Exploitability (how easy to exploit)
2. Business impact (what gets compromised)
3. Exposure level (public-facing vs internal)
4. Fix complexity (simple patch vs major changes)

Rank as Critical/High/Medium/Low priority with justification.
```

예상 결과: 비즈니스 중심의 위험 평가를 포함한 우선순위가 정해진 취약성 목록입니다.

### 3단계:  수정 계획 생성 {#step-3-generate-fix-plans}

우선순위가 높은 취약성의 경우 취약성 해결 또는 Chat을 사용하여 구체적인 수정 지침을 받습니다.

```plaintext
Provide a detailed remediation plan for this [vulnerability_type]:

1. Immediate steps to reduce risk
2. Code changes needed (with examples)
3. Configuration updates required
4. Testing approach to verify the fix
5. Timeline estimate for implementation

Focus on [security_framework] compliance and our [coding_standards].
```

예상 결과: 구체적인 구현 단계를 포함한 실행 가능한 수정 계획입니다.

## 팁 {#tips}

- 심각 및 높음 심각도 취약성부터 시작합니다.
- 수정으로 들어가기 전에 취약성 설명을 사용하여 상황을 파악합니다.
- 비즈니스 영향을 평가할 때 특정 애플리케이션 아키텍처를 고려합니다.
- 잘 모르는 기술 용어나 공격 벡터를 설명하도록 GitLab Duo Chat에 요청합니다.
- 유사한 취약성을 함께 그룹화하여 일괄 분석 및 일관된 수정을 수행합니다.
- 보안 대시보드를 사용하여 수정 노력의 진행 상황을 추적합니다.

## 검증 {#verify}

다음을 확인합니다:

- 우선순위 순위가 CVSS 점수뿐만 아니라 실제 비즈니스 위험을 반영합니다.
- 수정 계획에 구체적인 코드 예제 및 테스트 단계가 포함됩니다.
- 거짓 양성이 명확하게 식별되고 문서화됩니다.
- 심각 취약성에 대해 즉시 완화 전략이 식별됩니다.
- 수정 일정이 현실적이고 테스트 및 배포 프로세스를 고려합니다.
