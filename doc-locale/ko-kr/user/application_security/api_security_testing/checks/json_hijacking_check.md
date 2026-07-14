---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: JSON 하이재킹
---

## 설명 {#description}

하이재킹에 취약할 수 있는 JSON 데이터를 확인합니다. 이 확인은 JSON 배열을 반환하는 GET 요청을 찾으며, 이는 잠재적으로 하이재킹되어 악의적인 웹사이트에서 읽힐 수 있습니다.

## 수정 {#remediation}

JSON 하이재킹을 통해 공격자는 악의적인 웹사이트 또는 유사한 공격 벡터를 통해 GET 요청을 보낼 수 있으며, 사용자의 저장된 자격 증명을 활용하여 그 사용자가 접근할 수 있는 민감한 데이터 또는 보호된 데이터를 검색할 수 있습니다. JSON 배열 그 자체는 유효한 JavaScript이므로, JavaScript 배열만 반환하는 리소스에 대한 악의적인 GET 요청을 통해 공격자는 악의적인 스크립트를 사용하여 요청에서 배열의 데이터를 읽을 수 있습니다. GET 요청은 리소스가 접근을 위해 인증을 요구하더라도 JSON 배열을 반환하면 안 됩니다. 이 요청에 GET 대신 POST를 사용하거나 배열을 JSON 객체로 래핑하는 것을 고려하세요.

## 링크 {#links}

- [OWASP](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- [CWE](https://cwe.mitre.org/data/definitions/352.html)
