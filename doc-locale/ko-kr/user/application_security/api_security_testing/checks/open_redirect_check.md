---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 열린 리다이렉트
---

## 설명 {#description}

열린 리다이렉트를 식별하고 공격자가 이를 악용할 수 있는지 확인합니다.

## 수정 {#remediation}

웹 애플리케이션이 신뢰할 수 없는 입력을 수용할 때 검증되지 않은 리다이렉트 및 전달이 발생할 수 있습니다. 이러한 입력으로 인해 웹 애플리케이션이 신뢰할 수 없는 입력에 포함된 URL로 요청을 리다이렉트할 수 있습니다. 신뢰할 수 없는 URL 입력을 악의적인 사이트로 수정하면 공격자가 피싱 사기를 성공적으로 시작하고 사용자 자격 증명을 도용할 수 있습니다. 수정된 링크의 서버 이름이 원본 사이트와 동일하므로 피싱 시도가 더 신뢰할 수 있는 것으로 보일 수 있습니다. 검증되지 않은 리다이렉트 및 전달 공격을 통해 애플리케이션의 액세스 제어 확인을 통과한 후 공격자를 일반적으로 액세스할 수 없는 권한이 있는 기능으로 전달하는 URL을 악의적으로 만들 수 있습니다.

## 링크 {#links}

- [OWASP](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- [CWE](https://cwe.mitre.org/data/definitions/601.html)
