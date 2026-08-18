---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 평문 인증
---

## 설명 {#description}

이 검사는 TLS가 없는 HTTP 기본 인증과 같은 평문 인증을 확인합니다.

## 수정 {#remediation}

인증 자격 증명이 암호화되지 않은 채널(HTTP)을 통해 전송됩니다. 전송 중에 네트워크 트래픽을 모니터링(스니핑)할 수 있는 모든 공격자에게 전송된 자격 증명이 노출됩니다. 자격 증명과 같은 민감한 정보는 항상 HTTPS와 같은 암호화된 채널을 통해 전송되어야 합니다.

## 링크 {#links}

- [OWASP](https://owasp.org/Top10/A02_2021-Cryptographic_Failures/)
- [CWE](https://cwe.mitre.org/data/definitions/319.html)
