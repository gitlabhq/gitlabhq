---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 오프라인 구성
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

제한된, 차단된 또는 간헐적인 인터넷 액세스 환경에 있는 인스턴스의 경우 DAST 작업을 성공적으로 실행하려면 일부 조정이 필요합니다. 자세한 내용은 [오프라인 환경](../../../offline_deployments/_index.md)을(를) 참조하세요.

## 오프라인 DAST 지원 요구 사항 {#requirements-for-offline-dast-support}

오프라인 환경에서 모든 버전의 DAST를 사용할 수 있습니다. 이렇게 하려면 다음이 필요합니다:

- [`docker` 또는 `kubernetes` 실행기](../_index.md)가 있는 러너. 러너는 대상 애플리케이션에 네트워크 액세스할 수 있어야 합니다.
- 컨테이너 레지스트리에서 로컬에서 사용 가능한 DAST [container image](https://gitlab.com/security-products/dast) 복사본이 있으며, [DAST container registry](https://gitlab.com/security-products/dast/container_registry)에서 찾을 수 있습니다. [오프라인 호스트로 Docker 이미지 로드](../../../offline_deployments/_index.md#loading-docker-images-onto-your-offline-host)를 참조하세요.

러너는 [`pull policy`의 기본값이 `always`](https://docs.gitlab.com/runner/executors/docker/#using-the-always-pull-policy)이며, 이는 로컬 복본이 있더라도 러너가 GitLab 컨테이너 레지스트리에서 Docker 이미지를 가져오려고 시도함을 의미합니다. 로컬에서 사용 가능한 Docker 이미지만 사용하는 것을 선호하는 경우, 오프라인 환경에서 러너 [`pull_policy`를 `if-not-present`](https://docs.gitlab.com/runner/executors/docker/#using-the-if-not-present-pull-policy)로 설정할 수 있습니다. 그러나 오프라인 환경에 있지 않은 경우 끌어오기 정책 설정을 `always`로 유지해야 합니다. 이 설정을 사용하면 CI/CD 파이프라인에서 업데이트된 스캐너를 사용할 수 있습니다.

## Docker 레지스트리 내에서 GitLab DAST 분석기 이미지를 사용할 수 있도록 설정 {#make-gitlab-dast-analyzer-images-available-inside-your-docker-registry}

DAST의 경우 `registry.gitlab.com`에서 다음 기본 DAST 분석기 이미지를 [로컬 Docker 컨테이너 레지스트리](../../../../packages/container_registry/_index.md)로 가져옵니다:

- `registry.gitlab.com/security-products/dast:latest`

Docker 이미지를 로컬 오프라인 Docker 레지스트리로 가져오는 프로세스는 **네트워크 보안 정책**에 따라 다릅니다. IT 직원에게 외부 리소스를 가져오거나 일시적으로 액세스할 수 있는 승인된 프로세스를 확인하도록 요청하세요. 이 스캐너는 [정기적으로 업데이트되며](../../../detect/vulnerability_scanner_maintenance.md), 새로운 정의가 나오면 자체적으로 가끔 업데이트할 수 있습니다.

Docker 이미지를 파일로 저장하고 전송하는 방법에 대한 자세한 내용은 Docker 문서에서 [`docker save`](https://docs.docker.com/reference/cli/docker/image/save/), [`docker load`](https://docs.docker.com/reference/cli/docker/image/load/), [`docker export`](https://docs.docker.com/reference/cli/docker/container/export/) 및 [`docker import`](https://docs.docker.com/reference/cli/docker/image/import/)를 참조하세요.

## 로컬 DAST 분석기를 사용하도록 DAST CI/CD 작업 변수 설정 {#set-dast-cicd-job-variables-to-use-local-dast-analyzers}

다음 구성을 `.gitlab-ci.yml` 파일에 추가합니다. `image`를 로컬 Docker 컨테이너 레지스트리에 호스팅된 DAST Docker 이미지를 참조하도록 바꿔야 합니다:

```yaml
include:
  - template: DAST.gitlab-ci.yml
dast:
  image: registry.example.com/namespace/dast:latest
```

DAST 작업은 이제 로컬 DAST 분석기 복사본을 사용하여 코드를 스캔하고 인터넷 액세스 없이 보안 보고서를 생성합니다.

또는 CI/CD 변수 `SECURE_ANALYZERS_PREFIX`를 사용하여 `dast` 이미지의 기본 레지스트리 주소를 재정의할 수 있습니다.
