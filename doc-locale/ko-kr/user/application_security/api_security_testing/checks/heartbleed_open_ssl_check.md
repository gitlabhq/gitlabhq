---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Heartbleed OpenSSL 취약성
---

## 설명 {#description}

Heartbleed OpenSSL 취약성을 확인합니다.

## 수정 {#remediation}

Heartbleed 취약성은 널리 사용되는 OpenSSL 암호화 라이브러리의 심각한 버그입니다. OpenSSL은 통신을 암호화하고 해독하며 인터넷 트래픽을 보호하는 데 사용됩니다. 이 취약성은 공격자가 보호된 정보를 탈취할 수 있게 하며, 이러한 정보는 민감한 정보를 암호화하는 데 사용되는 비밀 키와 같이 다른 상황에서는 접근할 수 없어야 합니다.

대상 API에 액세스할 수 있는 모든 사용자는 Heartbleed 취약성을 사용하여 OpenSSL 라이브러리의 취약한 버전을 악용하여 보호된 시스템의 메모리를 읽을 수 있습니다.

## 링크 {#links}

- [OWASP](https://owasp.org/Top10/A06_2021-Vulnerable_and_Outdated_Components/)
- [CWE](https://cwe.mitre.org/data/definitions/119.html)
