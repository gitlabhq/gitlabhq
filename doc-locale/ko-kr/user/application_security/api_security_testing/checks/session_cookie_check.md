---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 세션 쿠키
---

## 설명 {#description}

세션 쿠키에 올바른 플래그와 만료 시간이 설정되어 있는지 확인합니다.

## 수정 {#remediation}

HTTP는 상태 비저장 프로토콜이므로 웹사이트는 일반적으로 쿠키를 사용하여 각 요청에서 사용자를 고유하게 식별하는 세션 ID를 저장합니다. 따라서 각 세션 ID의 기밀성을 유지하여 여러 사용자가 동일한 계정에 액세스하는 것을 방지해야 합니다. 탈취된 세션 ID는 다른 사용자의 계정을 확인하거나 부정한 거래를 수행하는 데 사용될 수 있습니다.

- 세션 ID를 보호하는 한 가지 방법은 이들이 올바르게 만료되도록 표시하고 플레인텍스트로 전송되거나 스크립팅으로 액세스되지 않도록 올바른 플래그 집합을 요구하는 것입니다.
- HttpOnly는 Set-Cookie HTTP 응답 헤더에 포함되는 추가 플래그입니다. 쿠키를 생성할 때 HttpOnly 플래그를 사용하면 클라이언트 측 스크립트가 보호된 쿠키에 액세스하는 위험을 완화하는 데 도움이 됩니다(브라우저가 이를 지원하는 경우). HTTP 응답 헤더에 HttpOnly 플래그(선택 사항)가 포함된 경우 클라이언트 측 스크립트를 통해 쿠키에 액세스할 수 없습니다(브라우저가 이 플래그를 지원하는 경우). 결과적으로 교차 사이트 스크립팅(XSS) 취약점이 존재하고 사용자가 실수로 이 취약점을 악용하는 링크에 액세스하더라도 브라우저는 쿠키를 제3자에게 공개하지 않습니다.
- HTTPS 세션의 민감한 쿠키에 대한 Secure 속성이 설정되지 않아 사용자 에이전트가 해당 쿠키를 HTTP 세션에서 평문으로 전송할 수 있습니다.
- 안전하지 않은 전송 프로토콜에서 사용되는 세션 관련 쿠키가 식별되었습니다. 안전하지 않은 전송 프로토콜은 SSL/TLS를 사용하여 연결을 보호하지 않는 프로토콜입니다. 이러한 프로토콜의 예로 'http'가 있습니다.
- 불충분한 세션 만료는 웹 애플리케이션이 공격자가 이전 세션 자격 증명이나 세션 ID를 인증에 다시 사용하도록 허용할 때 발생합니다. 불충분한 세션 만료는 사용자의 세션 식별자를 탈취하거나 재사용하는 공격에 대한 웹사이트의 노출을 증가시킵니다.

## 링크 {#links}

- [OWASP](https://owasp.org/Top10/A07_2021-Identification_and_Authentication_Failures/)
- [CWE](https://cwe.mitre.org/data/definitions/930.html)
