---
stage: AI Clients
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 리포지토리에서 레거시 코드를 리팩토링합니다.
title: 레거시 코드 리팩토링
---

기존 코드의 성능, 가독성 또는 유지보수성을 개선해야 할 때 다음 가이드라인을 따르세요.

- 예상 소요 시간: 15-30분
- 수준: 중급
- 사전 요구 사항: IDE에서 코드 파일 열기, GitLab Duo Chat 사용 가능

## 도전 과제 {#the-challenge}

기능을 손상시키지 않으면서 복잡하고 유지보수하기 어려운 코드를 깔끔하고 테스트 가능한 구성 요소로 변환합니다.

## 접근 방식 {#the-approach}

GitLab Duo Chat과 Code Suggestions를 사용하여 분석, 계획 및 구현합니다.

### 1단계:  분석 {#step-1-analyze}

GitLab Duo Chat을 사용하여 현재 상태를 이해합니다. 리팩토링하려는 코드를 선택한 다음 다음과 같이 질문하세요:

```plaintext
Analyze the [ClassName] in [file_path]. Focus on:
1. Current methods and their complexity
2. Performance bottlenecks
3. Areas where readability can be improved
4. Potential design patterns that could be applied

Provide specific examples from the code and suggest applicable refactoring patterns.
```

예상 결과: 구체적인 개선 제안이 포함된 상세한 분석입니다.

### 2단계:  계획 {#step-2-plan}

GitLab Duo Chat을 사용하여 구조화된 제안을 작성합니다.

```plaintext
Based on your analysis of [ClassName], create a refactoring plan:

1. Outline the new structure
2. Suggest new method names and their purposes
3. Identify any new classes or modules needed
4. Explain how this improves [performance/readability/maintainability]

Format as a structured plan with clear before/after comparisons.
```

예상 결과: 단계별 리팩토링 로드맵입니다.

### 3단계:  구현 {#step-3-implement}

GitLab Duo Chat을 사용하여 리팩토링된 코드를 생성합니다. 그런 다음 코드를 적용하고 Code Suggestions를 사용하여 구문을 지원합니다.

```plaintext
Implement the refactoring plan for [ClassName]:

1. Create the new [language] file following our coding standards
2. Include detailed comments explaining changes
3. Update [related_file] to use the new structure
4. Write tests for the new implementation

Follow [style_guide] and document any design decisions.
```

예상 결과: 테스트가 포함된 완전한 리팩토링 코드입니다.

## 팁 {#tips}

- 구현으로 바로 넘어가기 전에 분석부터 시작하세요.
- Chat에 분석을 요청할 때 특정 코드 섹션을 선택하세요.
- 실제 코드의 구체적인 예시를 Chat에 요청하세요.
- 일관성을 위해 기존 코드베이스 패턴을 참조하세요.
- 한 번에 모든 작업을 하려고 하지 말고 증분 프롬프트를 사용하세요.
- Chat의 권장 사항을 구현할 때 Code Suggestions가 구문을 지원하도록 하세요.

## 확인 {#verify}

다음 사항을 확인하세요:

- 생성된 코드가 팀의 스타일 가이드를 따릅니다.
- 새 구조가 실제로 식별된 문제를 개선합니다.
- 테스트가 리팩토링된 기능을 포함합니다.
- 리팩토링 중에 기능이 손실되지 않았습니다.
