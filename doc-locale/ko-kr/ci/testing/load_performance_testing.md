---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: k6 로드 테스트를 사용하여 브랜치 간에 애플리케이션 백엔드 성능을 측정하고 비교합니다.
title: 로드 성능 테스트
---

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

로드 성능 테스트를 사용하여 코드 변경이 애플리케이션 백엔드 성능에 미치는 영향을 측정합니다. GitLab은 [k6](https://k6.io/)을 사용하여 API 및 웹 컨트롤러와 같은 애플리케이션 엔드포인트에 대한 로드를 시뮬레이션하고 `load-performance.json`이라는 파일에 결과를 출력합니다.

웹 페이지가 브라우저에서 렌더링되는 방식을 측정하는 [브라우저 성능 테스트](browser_performance_testing.md)와 달리 로드 성능 테스트는 서버 측을 대상으로 하며 로드 상태에서 응답 시간과 처리량을 평가할 수 있습니다.

결과는 머지 리퀘스트에 직접 표시되므로 검토 프로세스의 일부로 성능 저하를 발견할 수 있습니다.

## 머지 리퀘스트에서 로드 성능 결과 {#load-performance-results-in-merge-requests}

`.gitlab-ci.yml` 파일에 [로드 성능 리포트 아티팩트](../yaml/artifacts_reports.md#artifactsreportsload_performance)를 생성하는 작업을 정의합니다. GitLab은 이 리포트를 확인하고 소스 및 대상 브랜치 간의 주요 로드 성능 메트릭을 비교한 후 결과를 머지 리퀘스트에 표시합니다.

![머지 리퀘스트에서 성능 메트릭과 저하된 TTFB 값을 표시합니다.](img/load_performance_testing_v18_11.png)

머지 리퀘스트 위젯에 표시되는 주요 메트릭은 다음과 같습니다:

- **점검**: k6 테스트에서 구성된 [checks](https://k6.io/docs/using-k6/checks)의 통과율 백분율입니다.
- **TTFB P90**: 응답을 받기 시작할 때까지 걸린 시간의 90번째 백분위수로, [Time to First Byte](https://en.wikipedia.org/wiki/Time_to_first_byte) (TTFB)라고도 합니다.
- **TTFB P95**: TTFB의 95번째 백분위수입니다.
- **RPS**: 테스트가 달성할 수 있는 평균 초당 요청(RPS) 비율입니다.

> [!note]
> 대상 브랜치에서 작업이 최소한 한 번 이상 실행될 때까지 위젯이 표시되지 않습니다.

## 로드 성능 테스트 구성 {#configure-load-performance-testing}

GitLab에 포함된 [`Verify/Load-Performance-Testing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Verify/Load-Performance-Testing.gitlab-ci.yml) 템플릿을 사용하여 애플리케이션에 대해 [k6 로드 테스트](https://k6.io/docs/testing-guides)를 실행합니다.

전제 조건:

- 러너가 Docker 컨테이너를 실행하도록 구성되어 있습니다(예: [Docker-in-Docker 워크플로우](../docker/using_docker_build.md#use-docker-in-docker)).
- 로드 테스트를 위해 구성된 사전 프로덕션 테스트 환경입니다. 자세한 내용은 [로드 테스트를 위한 동시 사용자 계산](https://k6.io/blog/monthly-visits-concurrent-users)을 참조하세요.
- 프로젝트 리포지토리의 k6 테스트 파일입니다. 지침은 [첫 번째 k6 테스트 작성](https://grafana.com/docs/k6/latest/get-started/write-your-first-test/)을 참조하세요.

로드 성능 테스트를 구성하려면 `.gitlab-ci.yml` 파일에 다음을 추가합니다:

```yaml
include:
  template: Verify/Load-Performance-Testing.gitlab-ci.yml

load_performance:
  variables:
    K6_TEST_FILE: <PATH TO K6 TEST FILE IN PROJECT>
```

GitLab은 k6 테스트를 실행하고 결과를 [로드 성능 리포트 아티팩트](../yaml/artifacts_reports.md#artifactsreportsload_performance)로 저장하는 `load_performance` 작업을 생성합니다. 사용 가능한 최신 아티팩트가 항상 사용됩니다. [GitLab Pages](../../user/project/pages/_index.md)가 활성화되어 있으면 브라우저에서 직접 리포트를 볼 수 있습니다.

CI/CD 변수로 작업을 사용자 지정할 수 있습니다:

| 변수            | 기본값      | 설명 |
| ------------------- | ------------ | ----------- |
| `K6_IMAGE`          | `grafana/k6` | 사용할 Docker 이미지입니다. 버전을 제어하지 않습니다. |
| `K6_VERSION`        | `0.54.0`     | Docker 이미지의 버전입니다. |
| `K6_TEST_FILE`      | 없음         | 프로젝트 리포지토리의 k6 테스트 파일 경로입니다. |
| `K6_OPTIONS`        | 없음         | 추가 k6 옵션입니다. 자세한 내용은 [k6 옵션 참조](https://k6.io/docs/using-k6/k6-options/reference/)를 참조하세요. |
| `K6_DOCKER_OPTIONS` | 없음         | `docker run`에 전달된 추가 옵션(예: `--env-file`)을 사용하여 k6 컨테이너에 환경 변수를 전달합니다. |

예를 들어 테스트의 기간을 재정의하려면:

```yaml
include:
  template: Verify/Load-Performance-Testing.gitlab-ci.yml

load_performance:
  variables:
    K6_TEST_FILE: <PATH TO K6 TEST FILE IN PROJECT>
    K6_OPTIONS: '--duration 30s'
```

> [!note]
> 이 템플릿은 Kubernetes 클러스터에서 작동하지 않습니다. 대신 [`Jobs/Load-Performance-Testing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Load-Performance-Testing.gitlab-ci.yml)를 사용하세요.

대규모 k6 테스트의 경우 러너 인스턴스가 로드를 처리할 수 있는지 확인합니다. [기본 공유 GitLab.com 러너](../runners/hosted_runners/linux.md)는 대부분의 대규모 k6 테스트에 사양이 부족할 가능성이 있습니다. 자세한 내용은 [대규모 테스트 실행 관련 k6 지침](https://k6.io/docs/testing-guides/running-large-tests#hardware-considerations)을 참조하세요.

### 검토 앱에 대한 로드 성능 테스트 구성 {#configure-load-performance-testing-for-review-apps}

전제 조건:

- `load_performance` 작업은 동적 환경이 시작된 후 실행되어야 합니다.

검토 앱에 대한 로드 성능 테스트를 구성하려면 동적 URL을 [`.env` 파일](https://docs.docker.com/compose/environment-variables/env-file/)에 캡처하고 `K6_DOCKER_OPTIONS`을 사용하여 k6 컨테이너에 전달합니다. 그러면 k6은 표준 JavaScript를 사용하여 테스트 스크립트의 파일에서 환경 변수를 사용할 수 있습니다. 예: ``http.get(`${__ENV.ENVIRONMENT_URL}`)``

예를 들어:

```yaml
stages:
  - deploy
  - performance

include:
  template: Verify/Load-Performance-Testing.gitlab-ci.yml

review:
  stage: deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: http://$CI_ENVIRONMENT_SLUG.example.com
  script:
    - run_deploy_script
    - echo "ENVIRONMENT_URL=$CI_ENVIRONMENT_URL" >> review.env
  artifacts:
    paths:
      - review.env
  rules:
    - if: $CI_COMMIT_BRANCH

load_performance:
  dependencies:
    - review
  variables:
    K6_DOCKER_OPTIONS: '--env-file review.env'
  rules:
    - if: $CI_COMMIT_BRANCH
```
