---
stage: AI Clients
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 기존 함수 및 클래스에 대한 포괄적인 테스트를 생성합니다.
title: 기존 코드에 대한 테스트 생성
---

기존 함수 또는 클래스에 대한 포괄적인 테스트 커버리지를 만들어야 할 때 다음 가이드라인을 따르세요.

- 예상 소요 시간: 10-20분
- 수준: 초급
- 사전 요구 사항: IDE에서 코드 파일이 열려 있음, GitLab Duo Chat 사용 가능, 테스트할 기존 코드

## 도전 과제 {#the-challenge}

보일러플레이트 테스트 케이스와 설정 코드를 수동으로 작성하지 않고 기존 코드에 대한 철저한 테스트 커버리지를 만듭니다.

## 접근 방식 {#the-approach}

GitLab Duo Chat 및 Code Suggestions을 사용하여 코드를 선택하고, 테스트를 생성하고, 커버리지를 개선합니다.

### 1단계:  생성 {#step-1-generate}

테스트하려는 함수 또는 클래스를 선택한 다음, GitLab Duo Chat을 사용하여 테스트를 생성합니다.

```plaintext
Generate tests for the selected [function_name/ClassName] by using [test_framework]:

1. Include test cases for normal operation
2. Add edge cases and error conditions
3. Test boundary values and invalid inputs
4. Follow [testing_conventions] for our project
5. Include setup and teardown if needed

Make the tests comprehensive but readable.
```

예상 결과: 다양한 시나리오를 다루는 여러 테스트 케이스가 포함된 완전한 테스트 파일입니다.

### 2단계:  개선 {#step-2-refine}

생성된 테스트를 검토하고 구체적인 개선사항을 요청합니다.

```plaintext
Review the generated tests and:
1. Add any missing edge cases for [specific_functionality]
2. Improve test names to be more descriptive
3. Add comments explaining complex test scenarios
4. Ensure tests follow [specific_style_guide]

Focus on making tests maintainable and clear.
```

예상 결과: 명확하고 포괄적인 커버리지를 제공하는 개선된 테스트 파일입니다.

### 3단계:  확장 {#step-3-extend}

Code Suggestions을 사용하여 추가 테스트 케이스를 추가합니다. 파일에 이 텍스트를 입력하세요.

```plaintext
// Test [specific_edge_case_scenario]
// Test [error_condition]
// Test [boundary_condition]
```

예상 결과: Code Suggestions은 추가 테스트 케이스를 완성하는 데 도움이 됩니다.

## 팁 {#tips}

- 더 나은 결과를 얻으려면 전체 파일이 아닌 특정 함수 또는 클래스를 선택하세요.
- 테스트 프레임워크에 대해 구체적으로 지정하세요(예: Jest, pytest, RSpec).
- 학습 중이라면 Chat에 테스트 케이스의 논리를 설명해 달라고 요청하세요.
- Code Suggestions을 사용하여 유사한 테스트 패턴을 빠르게 추가하세요.
- 철저한 커버리지를 위해 긍정적 및 부정적 테스트 케이스를 모두 요청하세요.

## 확인 {#verify}

다음 사항을 확인하세요:

- 테스트는 주요 기능과 일반적인 엣지 케이스를 포함합니다.
- 테스트 이름은 테스트되는 내용을 명확하게 설명합니다.
- 테스트는 프로젝트의 테스트 규칙 및 스타일을 따릅니다.
- 모든 테스트는 기존 코드에 대해 실행할 때 통과합니다.
