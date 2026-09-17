---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 애플리케이션 배포 옵션
---

DAST를 실행하려면 배포된 애플리케이션이 스캔 가능한 상태로 준비되어야 합니다.

대상 애플리케이션의 복잡성에 따라 DAST 템플릿을 배포하고 구성하는 몇 가지 옵션이 있습니다. 샘플 애플리케이션과 그 구성이 [DAST 데모](https://gitlab.com/gitlab-org/security-products/demos/dast/) 프로젝트에 제공됩니다.

## 검토 앱 {#review-apps}

검토 앱은 DAST 대상 애플리케이션을 배포하는 가장 복잡한 방법입니다. 이를 지원하기 위해 GitLab은 Google Kubernetes Engine(GKE)을 사용하는 검토 앱 배포를 만들었습니다. 이 예제는 [검토 앱 - GKE](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke) 프로젝트에서 찾을 수 있으며, DAST의 검토 앱을 구성하기 위한 자세한 지침은 [README](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke/-/blob/master/README.md)에서 확인할 수 있습니다.

## Docker 서비스 {#docker-services}

애플리케이션이 Docker 컨테이너를 사용하는 경우 DAST로 배포하고 스캔하는 다른 옵션이 있습니다. Docker 빌드 작업이 완료되고 이미지가 컨테이너 레지스트리에 추가되면 이미지를 [서비스](../../../../ci/services/_index.md)로 사용할 수 있습니다.

`.gitlab-ci.yml`에서 서비스 정의를 사용하면 DAST 분석기로 서비스를 스캔할 수 있습니다.

작업에 `services` 섹션을 추가할 때 `alias`는 서비스에 액세스하는 데 사용할 수 있는 호스트명을 정의하는 데 사용됩니다. 다음 예제에서 `alias: yourapp`는 `dast` 작업 정의의 일부이며, 배포된 애플리케이션의 URL이 호스트명으로 `yourapp`를 사용함을 의미합니다(`https://yourapp/`).

```yaml
stages:
  - build
  - dast

include:
  - template: DAST.gitlab-ci.yml

# Deploys the container to the GitLab container registry
deploy:
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

dast:
  services: # use services to link your app container to the dast job
    - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
      alias: yourapp

variables:
  DAST_TARGET_URL: https://yourapp
  DAST_FULL_SCAN: "true" # do a full scan
  DAST_BROWSER_SCAN: "true" # use the browser-based GitLab DAST crawler
```

대부분의 애플리케이션은 데이터베이스 또는 캐싱 서비스와 같은 여러 서비스에 의존합니다. 기본적으로 서비스 필드에 정의된 서비스는 서로 통신할 수 없습니다. 서비스 간 통신을 허용하려면 `FF_NETWORK_PER_BUILD` [기능 플래그](https://docs.gitlab.com/runner/configuration/feature-flags/#available-feature-flags)를 활성화합니다.

```yaml
variables:
  FF_NETWORK_PER_BUILD: "true" # enable network per build so all services can communicate on the same network

services: # use services to link the container to the dast job
  - name: mongo:latest
    alias: mongo
  - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    alias: yourapp
```
