---
stage: AI Clients
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 실패한 코드 또는 테스트의 버그를 식별하고 수정합니다.
title: 실패한 코드 디버깅
---

코드가 예상대로 작동하지 않거나 테스트가 실패하는 경우 다음 지침을 따르세요.

- 예상 소요 시간: 10-25분
- 수준: 초급
- 사전 요구 사항: 오류 메시지 또는 실패한 코드 사용 가능, IDE에서 GitLab Duo Chat 사용 가능

## 문제 {#the-challenge}

수동으로 몇 시간을 들이지 않고도 버그나 테스트 실패의 근본 원인을 빠르게 파악하고 효과적인 수정 방법을 구현합니다.

## 방법 {#the-approach}

GitLab Duo Chat을 사용하여 오류를 분석하고, 원인을 파악하고, 수정 방법을 구현합니다.

### 1단계:  분석 {#step-1-analyze}

오류 메시지와 관련 코드를 복사합니다. 그런 다음 GitLab Duo Chat에 오류를 설명해 달라고 요청합니다.

```plaintext
Explain what's causing this error and help me fix it:

Error: [paste_error_message]

Context: [brief_description_of_what_you_were_trying_to_do]

Here's the relevant code:
[paste_problematic_code]
```

예상 결과: 오류 원인에 대한 명확한 설명과 구체적인 수정 권장 사항입니다.

### 2단계:  구현 {#step-2-implement}

Chat에 수정된 코드를 제공하도록 요청합니다.

```plaintext
Based on your analysis, please provide the corrected version of this code:

[paste_original_code]

Make sure the fix addresses [specific_error] and follows [language/framework] best practices.
```

예상 결과: 파악된 이슈를 수정하는 작동 코드입니다.

### 3단계:  방지 {#step-3-prevent}

유사한 이슈를 피하는 방법에 대한 지침을 요청합니다.

```plaintext
How can I prevent this type of error in the future?
What are the warning signs to watch for with [error_type] in [language/framework]?
Include any best practices or common patterns I should follow.
```

예상 결과: 유사한 버그를 피하기 위한 예방 지침 및 모범 사례입니다.

## 팁 {#tips}

- 전체 오류 메시지를 포함하고, 요약만 포함하지 마세요.
- 수행하려던 작업에 대한 컨텍스트를 제공합니다.
- 실패한 특정 코드 섹션만 복사하는 것부터 시작합니다. Chat에 더 많은 컨텍스트가 필요하면 파일에서 더 많은 코드를 추가합니다.
- Chat에 수정 사항을 설명하도록 요청하여 기본 이슈를 이해합니다.
- 첫 번째 제안이 작동하지 않으면 Chat에 시도했을 때 어떤 일이 발생했는지 알려줍니다.

## 검증 {#verify}

다음을 확인합니다:

- 코드를 실행할 때 오류가 더 이상 발생하지 않습니다.
- 수정 사항이 증상이 아니라 근본 원인을 해결합니다.
- 솔루션이 프로젝트의 코딩 표준을 따릅니다.
- 오류가 발생한 이유와 수정 사항이 어떻게 작동하는지 이해합니다.
