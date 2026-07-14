---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 민감한 파일 공개
---

## 설명 {#description}

민감한 파일 공개에 대해 확인합니다. 이 확인은 민감한 정보를 포함할 수 있는 파일을 찾습니다. .htaccess, .htpasswd, .bash_history 등의 예가 있습니다.

## 수정 {#remediation}

정보 유출은 애플리케이션이 웹 애플리케이션의 기술적 세부 사항, 환경 또는 사용자별 데이터와 같은 민감한 데이터를 노출하는 애플리케이션 약점입니다. 민감한 데이터는 공격자가 대상 웹 애플리케이션, 호스팅 네트워크 또는 사용자를 악용하는 데 사용될 수 있습니다. 따라서 민감한 데이터의 유출은 가능한 한 제한되거나 방지되어야 합니다. 정보 유출은 가장 일반적인 형태에서 다음 조건 중 하나 이상의 결과입니다:  민감한 정보를 포함하는 HTML/Script 주석을 제거하지 못함, 부적절한 애플리케이션 또는 서버 구성, 또는 유효한 데이터 대 무효한 데이터에 대한 페이지 응답의 차이입니다.

이 실패의 경우 접근할 수 있어야 하지 않는 하나 이상의 파일 및/또는 폴더에 접근할 수 있습니다. 여기에는 명령 기록과 같은 홈 폴더에서 공통으로 사용되는 파일 또는 암호와 같은 비밀이 포함된 파일이 포함될 수 있습니다.

## 링크 {#links}

- [OWASP](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- [CWE](https://cwe.mitre.org/data/definitions/200.html)
