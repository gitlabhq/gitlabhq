---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API 보안 테스트 작업 재정의
---

작업 정의를 재정의하려면 `variables`, `dependencies`, 또는 [`rules`](../../../../ci/yaml/_index.md#rules)와 같은 속성을 변경하는 예를 들어, 작업을 재정의할 DAST 작업과 같은 이름으로 선언합니다. 템플릿 포함 선언 뒤에 이 새 작업을 배치하고 그 아래에 추가 키를 지정합니다. 예를 들어, 다음과 같이 대상 API의 기본 URL을 설정합니다:

```yaml
include:
  - template: Security/API-Security.gitlab-ci.yml

api_security:
  variables:
    APISEC_TARGET_URL: https://target/api
```
