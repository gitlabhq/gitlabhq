---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 민감한 정보 공개
---

## 설명 {#description}

민감한 정보 공개 확인. 신용카드 번호, 건강 기록, 개인 정보 등이 포함됩니다.

## 수정 {#remediation}

민감한 정보 누출은 애플리케이션이 민감하고 사용자별 데이터를 공개하는 애플리케이션 약점입니다. 민감한 데이터는 공격자가 사용자를 악용하는 데 사용될 수 있습니다. 따라서 민감한 데이터의 유출을 가능한 한 제한하거나 방지해야 합니다. 정보 누출은 일반적인 형태에서 유효한 데이터와 유효하지 않은 데이터에 대한 페이지 응답의 차이의 결과입니다.

유효성에 따라 다른 응답을 제공하는 페이지는 정보 누출로 이어질 수도 있습니다. 특히 웹 애플리케이션의 설계로 인해 기밀로 간주되는 데이터가 공개될 때입니다. 민감한 데이터의 예는 (이에 한정되지 않음): 계정 번호, 사용자 식별자(운전면허증 번호, 여권 번호, 사회보장번호 등) 및 사용자별 정보(비밀번호, 세션, 주소)입니다. 이 컨텍스트에서 정보 누출은 기밀 또는 비밀로 간주되며 사용자에게도 노출되어서는 안 되는 중요한 사용자 데이터의 노출을 다룹니다. 신용카드 번호 및 기타 규제가 많은 정보는 이미 적절한 암호화 및 액세스 제어가 있는 상황에서도 노출 또는 누출로부터 추가 보호가 필요한 사용자 데이터의 주요 예입니다.

## 링크 {#links}

- [OWASP](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- [CWE](https://cwe.mitre.org/data/definitions/200.html)
