---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: XML 외부 엔터티
---

## 설명 {#description}

XML DTD 처리 취약점을 확인합니다.

## 수정 {#remediation}

XML 외부 엔터티 공격은 XML 입력을 파싱하는 애플리케이션에 대한 공격 유형입니다. 이 공격은 외부 엔터티에 대한 참조를 포함하는 XML 입력이 약하게 구성된 XML 파서에 의해 처리될 때 발생합니다. 이 공격으로 인해 기밀 데이터 공개, 서비스 거부, 서버 측 요청 위조, 파서가 위치한 머신 관점에서의 포트 스캔, 기타 시스템 영향 등이 발생할 수 있습니다.

## 링크 {#links}

- [OWASP](https://owasp.org/Top10/A03_2021-Injection/)
- [CWE](https://cwe.mitre.org/data/definitions/611.html)
