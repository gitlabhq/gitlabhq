---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SQL 인젝션
---

## 설명 {#description}

SQL 및 NoSQL 인젝션 취약성을 확인합니다. SQL 인젝션 공격은 클라이언트에서 애플리케이션으로의 입력 데이터를 통해 SQL 쿼리를 삽입하는 것으로 구성됩니다. 성공한 SQL 인젝션 악용은 데이터베이스에서 민감한 데이터를 읽고, 데이터베이스 데이터를 수정(삽입/업데이트/삭제)하고, 데이터베이스에서 관리 작업(예: DBMS 종료)을 실행하고, DBMS 파일 시스템에 있는 특정 파일의 내용을 복구하고, 경우에 따라 운영 체제에 명령을 발급할 수 있습니다. SQL 인젝션 공격은 미리 정의된 SQL 명령 실행을 수행하기 위해 데이터 평면 입력에 SQL 명령을 주입하는 인젝션 공격의 한 유형입니다. 이 검사는 요청의 매개변수(경로, 쿼리 문자열, 헤더, JSON, XML 등)를 수정하여 SQL 또는 NoSQL 쿼리에서 구문 오류를 만들려고 시도합니다. 로그 및 응답을 분석하여 오류 발생 여부를 감지하려고 시도합니다. 오류가 감지되면 취약성이 존재할 가능성이 높습니다.

## 수정 {#remediation}

소프트웨어는 업스트림 구성 요소의 외부 영향을 받는 입력을 사용하여 SQL 명령의 전부 또는 일부를 구성하지만, 다운스트림 구성 요소로 전송될 때 의도된 SQL 명령을 수정할 수 있는 특수 요소를 중립화하지 않거나 잘못 중립화합니다.

사용자 제어 입력에서 SQL 구문을 충분히 제거하거나 인용하지 않으면, 생성된 SQL 쿼리는 해당 입력이 일반 사용자 데이터 대신 SQL로 해석되게 할 수 있습니다. 이를 통해 쿼리 논리를 변경하여 보안 검사를 우회하거나, 백엔드 데이터베이스를 수정하는 추가 문을 삽입하고, 경우에 따라 시스템 명령 실행을 포함할 수 있습니다.

SQL 인젝션은 데이터베이스 기반 웹사이트의 일반적인 이슈가 되었습니다. 이 결함은 쉽게 감지되고 쉽게 악용되므로, 최소한의 사용자 기반이 있는 모든 사이트 또는 소프트웨어 패키지는 이러한 종류의 공격 시도의 대상이 될 가능성이 높습니다. 이 결함은 SQL이 제어 평면과 데이터 평면 간에 실질적인 구분을 하지 않는다는 사실에 따라 달라집니다.

## 링크 {#links}

- [OWASP](https://owasp.org/Top10/A03_2021-Injection/)
- [CWE](https://cwe.mitre.org/data/definitions/930.html)
