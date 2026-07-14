---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Shellshock
---

## 설명 {#description}

Shellshock 취약성을 확인합니다.

## 수정 {#remediation}

Shellshock 취약성은 BASH의 버그를 이용하며, 이 버그에서는 BASH가 환경 변수에 저장된 함수 정의를 가져올 때 후행 명령을 잘못 실행합니다. BASH 환경 변수 정의를 허용하는 모든 환경은 이 버그에 취약할 수 있습니다. 예를 들어 mod_cgi 및 mod_cgid 모듈을 사용하는 Apache 웹 서버가 있습니다. 알려진 정상 요청이 악성 콘텐츠를 포함하도록 수정되었습니다. 악성 콘텐츠에는 Shell shock 공격이 포함되어 있으며, 여기서 서버 측 애플리케이션은 응답 헤더에서 특정 텍스트(증거)를 반환합니다.

## 링크 {#links}

- [OWASP](https://owasp.org/Top10/A03_2021-Injection/)
- [CWE](https://cwe.mitre.org/data/definitions/78.html)
