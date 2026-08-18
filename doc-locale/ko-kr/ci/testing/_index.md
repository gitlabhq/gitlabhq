---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab CI/CD를 사용한 테스트
description: "머지 리퀘스트에 표시되는 테스트 보고서, 코드 품질 분석 및 보안 스캔을 생성합니다."
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab CI/CD를 사용하여 기능 브랜치에서 변경 사항을 테스트합니다. 테스트 보고서를 표시하고 [머지 리퀘스트](../../user/project/merge_requests/_index.md)에서 직접 중요한 정보로 연결할 수 있습니다.

## 테스트 및 품질 보고서 {#testing-and-quality-reports}

다음 보고서를 생성할 수 있습니다:

| 기능                                                                                 | 설명 |
| --------------------------------------------------------------------------------------- | ----------- |
| [접근성 테스트](accessibility_testing.md)                                       | 변경된 페이지의 접근성 문제를 감지합니다. |
| [브라우저 성능 테스트](browser_performance_testing.md)                           | 코드 변경으로 인한 브라우저 성능 영향을 측정합니다. |
| [코드 커버리지](code_coverage/_index.md)                                                | 테스트 커버리지 결과, 차이점의 줄 단위 커버리지 및 전체 메트릭을 봅니다. |
| [코드 품질](code_quality.md)                                                         | Code Climate을 사용하여 소스 코드 품질을 분석합니다. |
| [작업 아티팩트 표시](../yaml/_index.md#artifactsexpose_as)                 | `artifacts:expose_as`를 사용하여 선택한 작업 아티팩트로 연결합니다. |
| [빠른 실패 테스트](fail_fast_testing.md)                                               | RSpec 테스트가 실패할 때 파이프라인을 조기에 중지합니다. |
| [라이선스 스캔](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md) | 종속성 라이선스를 스캔하고 관리합니다. |
| [로드 성능 테스트](load_performance_testing.md)                                 | 코드 변경으로 인한 서버 성능 영향을 측정합니다. |
| [메트릭 보고서](metrics_reports.md)                                                   | 메모리 사용량 및 성능과 같은 사용자 지정 메트릭을 추적합니다. |
| [단위 테스트 보고서](unit_test_reports.md)                                               | 작업 로그를 확인하지 않고 테스트 결과를 보고 실패를 식별합니다. |

## 보안 보고서 {#security-reports}

{{< details >}}

- 티어: Ultimate

{{< /details >}}

프로젝트를 취약점으로 스캔하여 [보안 보고서](../../user/application_security/_index.md)를 생성할 수 있습니다:

| 기능                                                                                       | 설명 |
| --------------------------------------------------------------------------------------------- | ----------- |
| [컨테이너 스캔](../../user/application_security/container_scanning/_index.md)            | Docker 이미지를 취약점으로 스캔합니다. |
| [동적 애플리케이션 보안 테스트(DAST)](../../user/application_security/dast/_index.md) | 실행 중인 웹 애플리케이션을 취약점으로 스캔합니다. |
| [종속성 검사](../../user/application_security/dependency_scanning/_index.md)          | 종속성을 취약점으로 스캔합니다. |
| [정적 애플리케이션 보안 테스팅(SAST)](../../user/application_security/sast/_index.md)  | 소스 코드를 취약점으로 스캔합니다. |
