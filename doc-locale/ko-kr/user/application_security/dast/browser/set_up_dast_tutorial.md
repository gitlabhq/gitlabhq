---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: '튜토리얼: 웹 애플리케이션을 검색할 DAST 설정'
---

<!-- vale gitlab_base.FutureTense = NO -->

사용자의 CI/CD 파이프라인에 DAST(Dynamic Application Security Testing)를 CI/CD 파이프라인에 통합하는 방법을 알아봅니다.

정적 분석은 소스 코드의 취약성을 찾습니다. DAST는 애플리케이션이 실제 환경에서 실행되고 서비스 및 사용자 워크플로우와 상호작용할 때만 나타나는 런타임 보안 문제를 식별합니다. GitLab 통합 DAST 솔루션을 사용하면 코드를 테스트 환경에 배포할 때마다 이러한 문제를 자동으로 확인하도록 GitLab DAST를 설정할 수 있습니다.

이 자습서에서는 다음을 배우게 됩니다:

1. [Tanuki Shop 애플리케이션 설정](#set-up-the-tanuki-shop-application)
1. [빌드 작업 정의](#define-the-build-job)
1. [DAST 작업 정의](#define-the-dast-job)
1. [수동 및 능동 검색 구성](#configure-passive-and-active-scanning)
1. [설정 확인](#verify-your-setup)

> [!note]
> 이 자습서의 Tanuki Shop 애플리케이션은 인증이 필요하지 않습니다. 애플리케이션에서 로그인이 필요한 경우 [DAST 인증](configuration/authentication.md)을 참조하세요.

## 시작하기 전에 {#before-you-begin}

- GitLab Ultimate 구독.
- 프로젝트의 Maintainer 역할.

## Tanuki Shop 애플리케이션 설정 {#set-up-the-tanuki-shop-application}

Tanuki Shop을 포크하여 시작합니다.

1. [Tanuki Shop 리포지토리](https://gitlab.com/gitlab-da/tutorials/security-and-governance/tanuki-shop)로 이동합니다.
1. 오른쪽 위에서 **포크**를 선택합니다.
1. 네임스페이스(개인 또는 그룹)를 선택하고 **프로젝트 포크**를 선택합니다.

   포크된 리포지토리에는 이 자습서에 필요한 모든 파일(애플리케이션 코드 및 초기 CI/CD 구성 포함)이 포함됩니다. 다음 단계에서 구성을 수정합니다.

1. **설정** > **일반**으로 이동합니다.
1. **표시 여부, 프로젝트 기능, 권한**을 확장합니다.
1. **컨테이너 레지스트리** 토글이 켜져 있는지 확인합니다.
1. 컨테이너 레지스트리가 작동 중인지 확인합니다:
   1. **배포** > **컨테이너 레지스트리**로 이동합니다.
   1. 빈 레지스트리가 표시되어야 합니다. 오류가 표시되면 프로젝트 권한을 확인합니다.

   > [!note]
   > 컨테이너 레지스트리는 파이프라인에서 빌드된 Docker 이미지를 저장합니다. 이 단계가 실패하면 빌드 작업도 나중에 실패합니다.

## 빌드 작업 정의 {#define-the-build-job}

이제 빌드 작업을 구성하여 애플리케이션이 포함된 Docker 이미지를 생성하고 컨테이너 레지스트리에 푸시합니다.

1. 프로젝트에서 `.gitlab-ci.yml` 파일을 편집합니다.
1. 기존 콘텐츠를 다음 CI/CD 구성으로 교체합니다:

   ```yaml
   stages:
     - build
     - dast

   include:
     - template: Security/DAST.gitlab-ci.yml

   # Build: Create the Docker image and push to the container registry
   build:
     services:
       - name: docker:dind
         alias: dind
     image: docker:20.10.16
     stage: build
     script:
       - docker login -u gitlab-ci-token -p $CI_JOB_TOKEN $CI_REGISTRY
       - docker pull $CI_REGISTRY_IMAGE:latest || true
       - docker build --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA --tag $CI_REGISTRY_IMAGE:latest .
       - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
       - docker push $CI_REGISTRY_IMAGE:latest
   ```

## DAST 작업 정의 {#define-the-dast-job}

빌드 작업을 구성했으므로 이제 DAST 작업을 구성합니다.

이 구성은 서비스 기능을 사용하여 DAST 작업과 병렬로 애플리케이션 컨테이너를 실행합니다. 애플리케이션은 URL `http://yourapp:3000`의 `dast` 작업에 액세스할 수 있습니다.

DAST 작업을 구성하려면:

- `.gitlab-ci.yml` 파일의 맨 아래에 다음을 추가합니다:

  ```yaml
  # DAST: Scan the application running in a Docker container
  dast:
    services:
      - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
        alias: yourapp
    variables:
      DAST_TARGET_URL: http://yourapp:3000
  ```

## 수동 및 능동 검색 구성 {#configure-passive-and-active-scanning}

DAST는 보안 검사 범위와 검색 시간 사이의 균형을 맞추는 두 가지 검색 모드를 지원합니다. 수동 검색은 빠른 피드백을 제공합니다. 능동 검색은 애플리케이션이 조작된 요청으로 테스트될 때만 발생하는 취약성을 발견하며, 코드가 프로덕션에 도달하기 전에 더 철저한 보안 검증을 제공합니다.

수동 검색(기본값, ~2-5분):

- 잠재적으로 해로운 요청을 보내지 않고 애플리케이션 응답을 분석합니다
- HTTP 헤더, 쿠키, 응답 콘텐츠 및 SSL/TLS 구성을 검사합니다
- 모든 환경에서 실행하기에 안전합니다
- CI/CD 파이프라인에서 빠른 피드백을 받기에 좋습니다

능동 검색(~10-30분, 애플리케이션 크기에 따라 다름):

- 취약성을 유발하도록 설계된 조작된 요청을 보냅니다
- 주입 결함, 인증 문제 및 비즈니스 논리 취약성을 테스트합니다
- 더 철저하지만 느립니다
- 주 브랜치로 병합하기 전에 기능 브랜치에 가장 적합합니다

> [!note]
> DAST 검색을 프로덕션 서버에 대해 실행하지 않습니다. 버튼 선택이나 양식 제출과 같이 사용자가 수행할 수 있는 모든 기능을 수행할 수 있을 뿐만 아니라 버그를 트리거할 수 있어 프로덕션 데이터의 수정 또는 손실로 이어질 수 있습니다. DAST 검색은 테스트 서버에 대해서만 실행합니다.

수동 및 능동 검색을 구성하려면:

- `.gitlab-ci.yml` 파일의 맨 아래에 다음을 추가합니다:

  ```yaml
    rules:
      - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH
        variables:
          DAST_FULL_SCAN: "false"  # Passive scan only for main branch (~2-5 mins)
      - if: $CI_COMMIT_REF_NAME != $CI_DEFAULT_BRANCH
        variables:
          DAST_FULL_SCAN: "true"   # Active scan for feature branches (~10-30 mins)
  ```

## 설정 확인 {#verify-your-setup}

DAST가 실행 중인 애플리케이션의 취약성을 성공적으로 발견할 수 있는지 확인합니다.

1. 파이프라인 편집기에서 **변경 사항 커밋**을 선택하고 `gitlab` 브랜치에 커밋합니다.

   파이프라인이 즉시 시작됩니다.
1. **빌드** > **파이프라인**으로 이동하여 최신 이 성공적으로 완료되었는지 확인합니다.

   예상 타임라인:
   - 빌드 스테이지: 2-3분(Docker 이미지 빌드)
   - DAST 스테이지: 2-5분(수동 검색)

1. 파이프라인이 성공적으로 완료된 후 **안전함** > **취약성 보고서**로 이동합니다.
1. 취약성을 검토합니다. 각 취약성에 대해 수행할 작업에 대한 도움은 [취약성을 수정하는 방법](../../remediate/_index.md)을 참조하세요.

> [!note]
> Tanuki Shop 애플리케이션은 데모 목적으로 의도적으로 취약합니다. 보안 정책과 관련된 발견, 개인 식별 정보(PII) 노출 및 기타 일반적인 웹 취약성을 볼 수 있습니다.

## 다음 단계 {#next-steps}

이 자습서를 완료한 후에는 다음을 수행할 수 있습니다:

- 특정 요구 사항에 맞게 [고급 DAST 설정](configuration/customize_settings.md)을 구성합니다.
- 임시 테스트를 위해 [주문형 DAST 검색](../on-demand_scan.md)을 설정합니다.
- DAST를 [취약성 관리 워크플로우](../../vulnerabilities/_index.md)와 통합합니다.
- [DAST 데모 리포지토리](https://gitlab.com/gitlab-org/security-products/demos/dast/)를 탐색하여 더 많은 예제를 확인합니다.

## 문제 해결 {#troubleshooting}

### 빌드 작업이 인증 오류로 실패함 {#build-job-fails-with-authentication-errors}

컨테이너 레지스트리 자격증명을 사용할 수 없을 때 인증 오류가 발생합니다.

이 문제를 해결하려면:

1. 컨테이너 레지스트리가 활성화되어 있는지 확인합니다:
   1. **설정** > **일반**으로 이동합니다.
   1. **표시 여부, 프로젝트 기능, 권한**을 확장합니다.
   1. **컨테이너 레지스트리** 토글이 켜져 있는지 확인합니다.

1. 프로젝트에 유효한 CI/CD 토큰이 있는지 확인합니다. GitLab은 `$CI_REGISTRY_USER`과(와) `$CI_REGISTRY_PASSWORD`를 자동으로 제공합니다.

### DAST 작업이 완료되었지만 취약성이 발견되지 않음 {#dast-job-completes-but-no-vulnerabilities-are-found}

이 문제는 DAST가 애플리케이션에 도달할 수 없거나 애플리케이션이 취약하지 않을 때 발생합니다.

이 이슈를 해결하려면:

1. 애플리케이션이 실행 중인지 확인합니다:

   ```shell
   curl "http://yourapp:3000"
   ```

1. DAST 작업 로그에서 연결 관련 오류를 확인합니다.
1. `DAST_TARGET_URL` 변수가 올바르게 설정되어 있는지 확인합니다(다음이어야 함: `http://yourapp:3000`).
1. Tanuki Shop 애플리케이션에는 취약성이 있어야 합니다. 취약성이 발견되지 않으면 올바른 포크된 리포지토리를 사용하고 있는지 확인합니다.

## 관련 항목 {#related-topics}

- [DAST 구성 참조](configuration/customize_settings.md)
- [보안 정책](../../policies/_index.md)
- [취약성 관리](../../vulnerabilities/_index.md)
- [애플리케이션 보안 테스트 솔루션](https://about.gitlab.com/solutions/application-security-testing/)
