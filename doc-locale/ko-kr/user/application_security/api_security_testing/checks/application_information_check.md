---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 애플리케이션 정보 공개
---

## 설명 {#description}

애플리케이션 정보 공개 확인입니다. 여기에는 버전 번호, 데이터베이스 오류 메시지, 스택 추적과 같은 정보가 포함됩니다.

## 수정 {#remediation}

애플리케이션 정보 공개는 애플리케이션이 웹 애플리케이션이나 환경의 기술 세부 정보와 같은 민감한 데이터를 노출하는 애플리케이션 약점입니다. 애플리케이션 데이터는 공격자가 대상 웹 애플리케이션, 호스팅 네트워크 또는 사용자를 악용하는 데 사용될 수 있습니다. 따라서 민감한 데이터의 유출을 가능한 한 제한하거나 방지해야 합니다. 정보 공개는 가장 일반적인 형태로 다음 조건 중 하나 이상의 결과입니다. 민감한 정보를 포함하는 HTML 또는 스크립트 주석을 제거하지 못하거나 부적절한 애플리케이션 또는 서버 구성입니다.

프로덕션 환경으로 푸시하기 전에 HTML 또는 스크립트 주석을 제거하지 못하면 서버 디렉토리 구조, SQL 쿼리 구조, 내부 네트워크 정보와 같은 민감한 상황별 정보가 유출될 수 있습니다. 종종 개발자는 사전 프로덕션 단계에서 디버깅 또는 통합 프로세스를 용이하게 하기 위해 HTML 및 스크립트 코드 내에 주석을 남깁니다. 개발자가 개발하는 콘텐츠 내에 인라인 주석을 포함하는 것이 해롭지 않지만, 콘텐츠를 공개하기 전에 이러한 주석을 모두 제거해야 합니다.

소프트웨어 버전 번호 및 자세한 오류 메시지(예: ASP.NET 버전 번호)는 부적절한 서버 구성의 예입니다. 이 정보는 웹 애플리케이션에서 사용 중인 프레임워크, 언어 또는 사전 빌드된 함수에 대한 상세한 통찰력을 제공함으로써 공격자에게 유용합니다. 대부분의 기본 서버 구성은 디버깅 및 문제 해결 목적으로 소프트웨어 버전 번호 및 자세한 오류 메시지를 제공합니다. 구성 변경을 통해 이러한 기능을 비활성화하여 이 정보의 표시를 방지할 수 있습니다.

## 링크 {#links}

- [OWASP](https://owasp.org/Top10/A05_2021-Security_Misconfiguration/)
- [CWE](https://cwe.mitre.org/data/definitions/200.html)
