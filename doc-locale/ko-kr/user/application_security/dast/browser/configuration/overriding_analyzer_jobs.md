---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: DAST 작업 재정의
---

작업 정의를 재정의하려면(예: `variables`, `dependencies`, 또는 [`rules`](../../../../../ci/yaml/_index.md#rules) 같은 속성을 변경하려면), 재정의할 DAST 작업과 같은 이름을 가진 작업을 선언하세요. 템플릿 포함 선언 뒤에 이 새 작업을 배치하고 그 아래에 추가 키를 지정합니다. 예를 들어, 다음은 분석기에 대한 인증 디버그 로깅을 활성화하여 로그 파일 아티팩트에 표시됩니다:

```yaml
include:
  - template: Security/DAST.gitlab-ci.yml

dast:
  variables:
    DAST_LOG_FILE_CONFIG: auth:debug
```
