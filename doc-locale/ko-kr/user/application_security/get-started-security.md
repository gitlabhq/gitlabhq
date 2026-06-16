---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 애플리케이션을 테스트하고 취약성을 해결하세요.
title: 애플리케이션 보안 시작하기
---

애플리케이션 소스 코드의 취약성을 식별하고 수정하세요. 코드를 자동으로 스캔하여 잠재적 보안 이슈를 찾음으로써 소프트웨어 개발 수명 주기에 보안 테스트를 통합하세요.

다양한 프로그래밍 언어와 프레임워크를 스캔할 수 있으며, SQL 삽입, 크로스 사이트 스크립팅(XSS), 취약한 종속성 같은 취약성을 감지할 수 있습니다. 보안 스캔 결과는 GitLab UI에 표시되며, 여기서 결과를 검토하고 해결할 수 있습니다.

이러한 기능은 머지 리퀘스트 및 파이프라인과 같은 다른 GitLab 기능과 통합되어 개발 프로세스 전반에 걸쳐 보안이 우선순위가 되도록 보장합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 개요는 [GitLab 애플리케이션 보안 도입](https://www.youtube.com/watch?v=5QlxkiKR04k)을 참조하세요.

<i class="fa-youtube-play" aria-hidden="true"></i> [대화형 읽기 및 방법 데모 재생목록 보기](https://www.youtube.com/playlist?list=PL05JrBw4t0KrUrjDoefSkgZLx5aJYFaF9)

이 프로세스는 더 큰 워크플로의 일부입니다:

![워크플로](img/get_started_app_sec_v16_11.png)

## 1단계:  스캔 학습 {#step-1-learn-about-scanning}

시크릿 검색은 리포지토리를 스캔하여 시크릿이 노출되는 것을 방지합니다. 모든 프로그래밍 언어에서 작동합니다.

종속성 검사는 알려진 취약성에 대해 애플리케이션의 종속성을 분석합니다. 특정 언어 및 패키지 관리자에서 작동합니다.

자세한 정보는 다음을 참조하세요:

- [시크릿 검색](secret_detection/_index.md)
- [종속성 검사](dependency_scanning/_index.md)

## 2단계:  테스트할 프로젝트 선택 {#step-2-choose-a-project-to-test}

GitLab 보안 스캔을 처음 설정하는 경우 단일 프로젝트부터 시작해야 합니다. 프로젝트는 다음을 충족해야 합니다:

- 조직의 일반적인 프로그래밍 언어 및 기술을 사용하세요. 일부 스캔 기능은 언어에 따라 다르게 작동하기 때문입니다.
- 팀의 일일 작업을 방해하지 않으면서 필수 승인과 같은 새 설정을 시도할 수 있어야 합니다. 트래픽이 많은 프로젝트의 복사본을 만들거나 덜 바쁜 프로젝트를 선택할 수 있습니다.

## 3단계:  스캔 활성화 {#step-3-enable-scanning}

프로젝트에서 유출된 시크릿과 취약한 패키지를 식별하려면 시크릿 검색 및 종속성 검사를 활성화하는 머지 리퀘스트를 만드세요.

이 머지 리퀘스트는 `.gitlab-ci.yml` 파일을 업데이트하여 스캔이 프로젝트 CI/CD 파이프라인의 일부로 실행되도록 합니다.

이 머지 리퀘스트의 일부로 프로젝트의 레이아웃이나 구성에 맞게 설정을 변경할 수 있습니다. 예를 들어 타사 코드 디렉터리를 제외할 수 있습니다.

이 머지 리퀘스트을 기본 브랜치에 머지한 후 시스템이 기준 검사를 생성합니다. 이 스캔은 기본 브랜치에 이미 존재하는 취약성을 식별합니다. 그러면 머지 리퀘스트에서 새로 발생한 문제를 강조합니다.

기준 검사가 없으면 머지 리퀘스트에서 취약성이 이미 기본 브랜치에 존재하더라도 브랜치의 모든 취약성을 표시합니다.

자세한 정보는 다음을 참조하세요:

- [시크릿 검색 활성화](secret_detection/pipeline/_index.md#getting-started)
- [시크릿 검색 설정](secret_detection/pipeline/configure.md)
- [종속성 검사 켜기](dependency_scanning/dependency_scanning_sbom/_index.md#turn-on-dependency-scanning)
- [종속성 검사 설정](dependency_scanning/dependency_scanning_sbom/_index.md#available-cicd-variables)

## 4단계:  스캔 결과 검토 {#step-4-review-scan-results}

팀원들이 머지 리퀘스트 및 취약성 보고서에서 보안 발견 사항을 확인하는 데 익숙해지도록 하세요.

취약성 심사 워크플로를 구축하세요. 취약성으로 인해 생성된 이슈를 관리하는 데 도움이 되도록 레이블과 이슈 보드를 만드는 것을 고려하세요. 이슈 보드를 사용하면 모든 이해 관계자가 모든 이슈에 대한 공통 보기를 가질 수 있으며 수정 진행 상황을 추적할 수 있습니다.

보안 대시보드 추세를 모니터링하여 기존 취약성 수정 및 새로운 취약성 도입 방지의 성공 여부를 측정하세요.

자세한 정보는 다음을 참조하세요:

- [취약성 보고서 보기](vulnerability_report/_index.md)
- [머지 리퀘스트에서 보안 발견 사항 보기](detect/security_scanning_results.md)
- [보안 대시보드 보기](security_dashboard/_index.md)
- [레이블](../project/labels.md)
- [이슈 보드](../project/issue_board.md)

## 5단계:  향후 스캔 작업 예약 {#step-5-schedule-future-scanning-jobs}

검사 실행 정책을 사용하여 예약된 보안 스캔 작업을 강제 실행하세요. 예약된 스캔 작업은 규정 준수 프레임워크 파이프라인 또는 프로젝트의 `.gitlab-ci.yml` 파일에서 정의했을 수 있는 다른 보안 스캔과 독립적으로 실행됩니다.

예약된 스캔은 개발 활동이 적고 파이프라인 스캔이 드문 프로젝트 또는 중요한 브랜치에 가장 유용합니다.

자세한 정보는 다음을 참조하세요:

- [검사 실행 정책](policies/scan_execution_policies.md)
- [컨테이너 스캔](container_scanning/_index.md)
- [운영 컨테이너 스캔](../clusters/agent/vulnerabilities.md)

## 6단계:  새로운 취약성 제한 {#step-6-limit-new-vulnerabilities}

필수 스캔 유형을 강제하고 보안과 엔지니어링 간의 직무 분리를 보장하려면 스캔 실행 정책을 사용하세요.

새로운 취약성이 기본 브랜치에 병합되는 것을 방지하려면 머지 리퀘스트 승인 정책을 만드세요.

스캔이 어떻게 작동하는지 숙지한 후에는 다음을 선택할 수 있습니다:

- 동일한 단계를 따라 더 많은 프로젝트에서 스캔을 활성화하세요.
- 더 많은 프로젝트에서 한 번에 스캔을 강제로 실행하세요.

자세한 정보는 다음을 참조하세요:

- [검사 실행 정책](policies/scan_execution_policies.md)
- [머지 리퀘스트 승인 정책](policies/_index.md)

## 7단계:  새로운 취약성을 계속 스캔 {#step-7-continue-scanning-for-new-vulnerabilities}

시간이 지남에 따라 새로운 취약성이 도입되지 않도록 해야 합니다.

- 리포지토리에 이미 존재하는 새로 발견된 취약성을 파악하려면 정기적인 종속성 및 컨테이너 스캔을 실행하세요.
- 프로덕션 클러스터의 컨테이너 이미지에서 보안 취약성을 스캔하려면 운영 컨테이너 스캔을 활성화하세요.
- SAST, DAST 또는 퍼징 테스트와 같은 다른 스캔 유형을 활성화하세요.
- 임시 테스트 환경에서 DAST 및 Web API 퍼징을 허용하려면 검토 앱 활성화를 고려하세요.

자세한 정보는 다음을 참조하세요:

- [SAST](sast/_index.md)
- [DAST](dast/_index.md)
- [퍼징 테스트](coverage_fuzzing/_index.md)
- [Web API 퍼징](api_fuzzing/_index.md)
- [검토 앱](../../ci/review_apps/_index.md)
