---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 안전하지 않은 HTTP 메서드
---

## 설명 {#description}

OPTIONS 및 TRACE와 같은 HTTP 메서드가 대상 엔드포인트에서 활성화되어 있는지 확인합니다.

## 수정 {#remediation}

테스트된 리소스는 OPTIONS HTTP 메서드를 지원합니다. 일반적으로 이는 보안 설정 오류로 간주되며, 지원되는 HTTP 메서드가 유출되어 특정 서버나 리소스에 대한 정보 수집으로 이어집니다. 그러나 OPTIONS를 자체 발견 메서드로 사용하려는 API 커뮤니티의 일부가 있습니다. OPTIONS를 활성화하기 위한 의도된 용도라면 이 이슈는 거짓 양성으로 간주될 수 있습니다.

테스트된 리소스는 TRACE HTTP 메서드를 지원합니다. 웹 브라우저의 다른 교차 도메인 취약점과 결합하면 헤더에서 민감한 정보가 유출될 수 있습니다. 서버/프레임워크에서 TRACE 메서드를 비활성화하는 것이 좋습니다.

## 링크 {#links}

- [OWASP](https://owasp.org/Top10/A05_2021-Security_Misconfiguration/)
- [CWE](https://cwe.mitre.org/data/definitions/200.html)
