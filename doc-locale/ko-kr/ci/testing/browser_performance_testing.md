---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: sitespeed.io를 사용하여 브랜치 간에 웹 페이지 렌더링 성능을 측정하고 비교합니다.
title: 브라우저 성능 테스트
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

브라우저 성능 테스트를 사용하여 웹 애플리케이션의 렌더링 성능을 측정하고 프로덕션에 도달하기 전에 회귀를 감지합니다. GitLab은 [sitespeed.io](https://www.sitespeed.io)를 사용하여 각 페이지의 점수를 매기고 결과를 `browser-performance.json`라는 파일에 출력합니다.

결과는 머지 리퀘스트에 직접 표시되므로 검토 프로세스의 일부로 성능 회귀를 포착할 수 있습니다. 예를 들어 `<head>`에 추가된 JavaScript 라이브러리로 인해 페이지 속도 점수가 하락합니다.

> [!note]
> [Auto DevOps](../../topics/autodevops/_index.md)를 사용하여 이 기능을 자동화할 수 있습니다.

## 머지 리퀘스트의 브라우저 성능 결과 {#browser-performance-results-in-merge-requests}

`.gitlab-ci.yml` 파일에 [브라우저 성능 보고서 아티팩트](../yaml/artifacts_reports.md#artifactsreportsbrowser_performance)를 생성하는 작업을 정의합니다. GitLab은 이 보고서를 확인하고, 소스 브랜치와 대상 브랜치 간에 각 페이지의 주요 성능 메트릭을 비교하며, 머지 리퀘스트에 결과를 표시합니다.

![성능 저하, 변경 없음, 개선된 값이 있는 브라우저 성능 메트릭입니다.](img/browser_performance_testing_v13_4.png)

> [!note]
> 작업이 대상 브랜치에서 최소한 한 번 실행되고 머지 리퀘스트의 최신 파이프라인에서 실행된 경우에만 위젯이 표시됩니다.

## 브라우저 성능 테스트 구성 {#configure-browser-performance-testing}

전제 조건:

- [Docker-in-Docker로 구성된 러너](../docker/using_docker_build.md#use-docker-in-docker).

[sitespeed.io 컨테이너](https://hub.docker.com/r/sitespeedio/sitespeed.io/)를 코드에서 실행하려면 Docker-in-Docker와 함께 GitLab CI/CD를 사용합니다:

1. `.gitlab-ci.yml` 파일에 다음을 추가합니다:

   ```yaml
   include:
     template: Verify/Browser-Performance.gitlab-ci.yml

   browser_performance:
     variables:
       URL: https://example.com
   ```

GitLab은 `browser_performance` 작업을 생성하여 URL에 대해 sitespeed.io를 실행하고 전체 HTML 보고서를 [브라우저 성능 아티팩트](../yaml/artifacts_reports.md#artifactsreportsbrowser_performance)로 저장합니다. [GitLab Pages](../../user/project/pages/_index.md)가 활성화되면 브라우저에서 보고서를 볼 수 있습니다.

> [!note]
> 이 템플릿은 Kubernetes 클러스터에서 작동하지 않습니다. 대신 [`template: Jobs/Browser-Performance-Testing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Browser-Performance-Testing.gitlab-ci.yml)를 사용합니다.

CI/CD 변수로 작업을 사용자 지정할 수 있습니다:

| 변수                   | 기본값                    | 설명 |
| -------------------------- | -------------------------- | ----------- |
| `SITESPEED_IMAGE`          | `sitespeedio/sitespeed.io` | 사용할 Docker 이미지입니다. 버전을 제어하지 않습니다. |
| `SITESPEED_VERSION`        | `14.1.0`                   | Docker 이미지의 버전입니다. |
| `SITESPEED_OPTIONS`        | 없음                       | 추가 sitespeed.io 옵션입니다. 자세한 내용은 [sitespeed.io 구성](https://www.sitespeed.io/documentation/sitespeed.io/configuration/)을 참조하세요. |
| `SITESPEED_DOCKER_OPTIONS` | 없음                       | `docker run`에 전달되는 추가 옵션(예: 특정 Docker 네트워크에 연결하기 위한 `--network`)입니다. |

예를 들어 실행 횟수를 재정의하고 버전을 변경합니다:

```yaml
include:
  template: Verify/Browser-Performance.gitlab-ci.yml

browser_performance:
  variables:
    URL: https://www.sitespeed.io/
    SITESPEED_VERSION: 13.2.0
    SITESPEED_OPTIONS: -n 5
```

### 성능 저하 임계값 구성 {#configure-the-degradation-threshold}

사소한 점수 하락에 대한 경고를 피하려면 `DEGRADATION_THRESHOLD` CI/CD 변수를 설정합니다. `Total Score`가 지정된 포인트 이상으로 저하될 때만 경고가 표시됩니다.

예를 들어:

```yaml
include:
  template: Verify/Browser-Performance.gitlab-ci.yml

browser_performance:
  variables:
    URL: https://example.com
    DEGRADATION_THRESHOLD: 5
```

`Total Score`은 성능, 접근성 및 모범 사례에 대한 0~100 사이의 종합 점수입니다. 100점은 페이지에 해결할 이슈가 없다는 의미입니다. 자세한 내용은 [코치가 페이지의 점수를 매기는 방법](https://www.sitespeed.io/documentation/coach/how-to/#what-do-the-coach-do)을 참조하세요.

### 검토 앱에 대한 브라우저 성능 테스트 구성 {#configure-browser-performance-testing-for-review-apps}

전제 조건:

- `browser_performance` 작업은 동적 환경이 시작된 후 실행되어야 합니다.

검토 앱에 대한 브라우저 성능 테스트를 구성하려면:

1. `review` 작업에서 동적 URL로 URL 목록 파일을 생성합니다:

   ```yaml
      script:
        - echo $CI_ENVIRONMENT_URL > environment_url.txt
   ```

1. 파일을 아티팩트로 저장합니다:

   ```yaml
      artifacts:
        paths:
          - environment_url.txt
   ```

1. 파일을 `URL` 변수로 `browser_performance` 작업에 전달합니다. 예를 들어:

   ```yaml
   stages:
     - deploy
     - performance

   include:
     template: Verify/Browser-Performance.gitlab-ci.yml

   review:
     stage: deploy
     environment:
       name: review/$CI_COMMIT_REF_SLUG
       url: http://$CI_COMMIT_REF_SLUG.$APPS_DOMAIN
     script:
       - run_deploy_script
       - echo $CI_ENVIRONMENT_URL > environment_url.txt
     artifacts:
       paths:
         - environment_url.txt
     rules:
       - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
         when: never
       - if: $CI_COMMIT_BRANCH

   browser_performance:
     dependencies:
       - review
     variables:
       URL: environment_url.txt
   ```
