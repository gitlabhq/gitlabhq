---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 인증 토큰
---

## 설명 {#description}

토큰 제거 또는 유효하지 않은 값으로 변경 등 다양한 인증 토큰 검사를 수행합니다.

## 수정 {#remediation}

API 토큰은 통계 분석 기법을 통해 공격자가 유효한 API 토큰을 추측하거나 예측할 수 있는 추측 공격을 방지하기 위해 예측 불가능해야 합니다. 이를 위해 좋은 PRNG(의사 난수 생성기)를 사용해야 합니다.

인증 토큰이 다음과 같이 변경되었을 수 있습니다:

- 유효하지 않은 값으로 수정됨.
- 요청에서 제거됨.
- 길이 요구 사항과 일치하지 않음.
- 서명으로 구성됨.

API 작업이 인증 토큰을 사용하여 액세스를 제한하지 못했습니다. 이를 통해 공격자가 인증을 우회하고 정보에 액세스하거나 데이터를 수정할 수 있습니다.

## 링크 {#links}

- [OWASP](https://owasp.org/Top10/A07_2021-Identification_and_Authentication_Failures/)
- [CWE](https://cwe.mitre.org/data/definitions/285.html)
