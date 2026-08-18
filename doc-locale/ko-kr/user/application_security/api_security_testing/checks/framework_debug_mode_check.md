---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프레임워크 디버그 모드
---

## 설명 {#description}

Flask 및 ASP.NET과 같은 다양한 프레임워크에서 디버그 모드가 활성화되어 있는지 확인합니다. 이 검사는 거짓 양성 비율이 낮습니다.

## 수정 {#remediation}

Flask 또는 ASP .NET 프레임워크가 디버그 모드가 활성화된 상태로 식별되었습니다. 이는 공격자가 파일 시스템의 모든 파일을 다운로드하고 다른 기능을 사용할 수 있도록 허용합니다. 이는 공격자가 쉽게 악용할 수 있는 높은 심각도 이슈입니다.

## 링크 {#links}

- [OWASP](https://owasp.org/Top10/A05_2021-Security_Misconfiguration/)
- [CWE-23: 상대 경로 순회](https://cwe.mitre.org/data/definitions/23.html)
- [CWE-285: 부적절한 권한 부여](https://cwe.mitre.org/data/definitions/285.html)
