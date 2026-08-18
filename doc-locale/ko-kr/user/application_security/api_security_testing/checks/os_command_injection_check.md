---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: OS 명령 주입
---

## 설명 {#description}

OS 명령 주입 취약성을 확인합니다. OS 명령 주입 공격은 클라이언트에서 애플리케이션으로 입력 데이터를 통해 OS 명령을 삽입 또는 "주입"하는 것으로 구성됩니다. 성공한 OS 명령 주입 악용은 임의의 명령을 실행할 수 있습니다. 이를 통해 공격자가 데이터를 읽고, 쓰고, 삭제할 수 있습니다. 명령이 실행되는 사용자에 따라 관리 기능도 포함될 수 있습니다.

이 검사는 요청의 매개변수(경로, 쿼리 문자열, 헤더, JSON, XML 등)를 수정하여 OS 명령을 실행하려고 합니다. 표준 주입과 블라인드 주입이 모두 수행됩니다. 블라인드 주입은 성공 시 응답에서 지연을 유발합니다.

## 수정 {#remediation}

대상 애플리케이션 서버에서 임의의 OS 명령을 실행할 수 있습니다. OS 명령 주입은 전체 시스템 손상으로 이어질 수 있는 중요한 취약성입니다. 사용자 입력은 OS 명령을 실행하는 함수의 명령이나 명령 인수를 구성하는 데 사용되어서는 안 됩니다. 여기에는 사용자 업로드 또는 다운로드로 제공된 파일 이름이 포함됩니다.

애플리케이션이 다음을 수행하지 않는지 확인합니다:

- 실행할 프로세스 이름에서 사용자가 제공한 정보를 사용합니다.
- 쉘 메타 문자를 이스케이프하지 않는 OS 명령 실행 함수에서 사용자가 제공한 정보를 사용합니다.
- OS 명령의 인수에서 사용자가 제공한 정보를 사용합니다.

애플리케이션은 OS 명령에 전달될 사전 정의된 인수 집합을 가져야 합니다. 파일 이름이 이러한 함수에 전달되는 경우 파일 이름의 해시를 대신 사용하거나 다른 고유 식별자를 사용하는 것이 좋습니다. 타사 명령에 대한 알려지지 않은 공격의 위험으로 인해 OS 시스템 명령을 사용하는 대신 동일한 기능을 구현하는 네이티브 라이브러리를 사용하는 것이 강력히 권장됩니다.

## 링크 {#links}

- [OWASP](https://owasp.org/Top10/A03_2021-Injection/)
- [CWE](https://cwe.mitre.org/data/definitions/78.html)
