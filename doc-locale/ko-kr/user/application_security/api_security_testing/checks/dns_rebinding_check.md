---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: DNS 리바인딩
---

## 설명 {#description}

DNS 리바인딩을 확인합니다. 이 확인은 호스트가 요청의 HOST 헤더가 존재하고 악성 DNS 항목을 통한 공격을 피하기 위해 호스트의 예상 이름과 일치하는지 확인합니다.

## 수정 {#remediation}

DNS 리바인딩을 통해 악의적인 호스트가 요청을 스푸핑하거나 대체 IP 주소로 리디렉션할 수 있으며, 이는 공격자가 보안 인증 또는 권한 부여를 우회할 수 있게 합니다. DNS 해석은 자체적으로만으로는 유효한 인증 메커니즘을 적절히 구성하지 않습니다. 서버는 요청의 Host 헤더가 서버의 예상 호스트명과 일치하는지 검증해야 합니다. 호스트명이 누락되었거나 예상 값과 일치하지 않는 경우 서버는 400을 반환해야 합니다. X-Forwarded-Host 헤더는 요청이 전달되는 경우에 Host 헤더 대신 사용되는 경우가 있습니다. 이러한 경우 X-Forwarded-Host 헤더도 원래 요청의 Host를 결정하는 데 사용되는 경우 검증해야 합니다.

## 링크 {#links}

- [OWASP](https://owasp.org/Top10/A05_2021-Security_Misconfiguration/)
- [CWE](https://cwe.mitre.org/data/definitions/350.html)
