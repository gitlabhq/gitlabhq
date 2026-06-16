---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 오프라인 환경에서 GitLab Duo 에이전트 플랫폼 자체 호스팅 배포
description: 컨테이너 이미지 및 LLM 모델 가중치를 내부 인프라로 전송하여 인터넷 접속 없이 GitLab Duo 자체 호스팅 실행
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- 자체 호스팅 모델 지원이 [일반 가용](https://gitlab.com/groups/gitlab-org/-/epics/12972) GitLab 17.9에서 제공됩니다.
- 오프라인 플로우 실행 지원이 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219672)되었습니다 GitLab 18.9.

{{< /history >}}

> [!note]
> 오프라인 환경을 설정하려면 구매 전에 [클라우드 라이센스의 옵트아웃 면제](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/#offline-cloud-licensing)를 받아야 합니다. 자세한 내용은 GitLab 영업 담당자에게 문의하세요.

GitLab 인스턴스 및 러너가 공용 인터넷에 액세스할 수 없는 오프라인 환경에서 GitLab Duo 에이전트 플랫폼 자체 호스팅을 배포할 수 있습니다. 이 지침은 연결이 제한되거나 방화벽 정책이 제한적인 환경에도 적용됩니다.

오프라인 환경에서는 AI 게이트웨이 컨테이너 이미지, LLM 모델 가중치, vLLM 추론 서버 이미지 및 에이전트 플랫폼 플로우 실행기 이미지를 내부 인프라로 수동으로 전송해야 합니다.

오프라인 환경에서 에이전트 플랫폼을 배포하려면 다음 단계를 완료하세요:

1. 컨테이너 이미지를 내부 레지스트리로 전송
1. LLM 모델 가중치를 오프라인 파일 시스템으로 전송
1. AI 게이트웨이 시작
1. vLLM 시작
1. GitLab 운영자에서 AI 게이트웨이 구성
1. 자체 호스팅 모델 추가
1. 오프라인 플로우 실행 구성
1. 배포 확인

## 필수 요구 사항 {#prerequisites}

- GitLab 18.9 이상(버전 [오프라인 클라우드 라이센스](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/#offline-cloud-licensing) 포함).
- 아티팩트를 다운로드할 수 있는 인터넷 연결 머신.
- [skopeo](https://github.com/containers/skopeo) 및 [jq](https://jqlang.github.io/jq/)가 연결된 머신 및 오프라인 호스트에 설치됨(Red Hat 시스템에서는 `dnf install --assumeyes skopeo jq`).
- 오프라인 환경으로 파일을 전송하는 방법(물리적 미디어, 크로스 도메인 솔루션 또는 배스천 호스트).
- 오프라인 환경의 컨테이너 레지스트리. 예를 들어 [GitLab 컨테이너 레지스트리](../../user/packages/container_registry/_index.md), Harbor 또는 Nexus.
- vLLM의 경우:  NVIDIA GPU 드라이버, CUDA 라이브러리 및 [NVIDIA 컨테이너 툴킷](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)이 추론 호스트에 설치됨. 오프라인 설치 옵션의 경우 [NVIDIA CUDA 설치 가이드](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/)를 참조하세요.

> [!note]
> 이 페이지의 모든 명령은 Docker 및 Podman에서 작동합니다. `docker`를 `podman`로 바꾸세요(적용 가능한 경우).

## 필수 아티팩트 {#required-artifacts}

LLM 모델 가중치를 제외한 모든 아티팩트는 OCI 컨테이너 이미지입니다.

### 컨테이너 이미지 {#container-images}

| 아티팩트 | 소스 레지스트리 | 태그 형식 | 대략적인 크기 |
|----------|----------------|------------|-----------------|
| AI 게이트웨이 | `registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway` | `self-hosted-vX.Y.Z-ee` | 340 MB |
| 에이전트 플랫폼 플로우 실행기 | `registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image` | `vX.Y.Z` | 2-3 GB |
| vLLM 추론 서버 | `docker.io/vllm/vllm-openai` | `vX.Y.Z`(v0.18.1 이상) | 2-4 GB |

AI 게이트웨이 태그는 GitLab 버전 번호를 사용합니다: `self-hosted-v<your-gitlab-version>-ee`.

현재 실행기 이미지 버전을 확인하려면 다음 명령을 실행하세요:

```shell
skopeo list-tags \
  docker://registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image \
  | jq --raw-output '.Tags[]' | grep --extended-regexp '^v[0-9]' | sort --version-sort | tail --lines=1
```

ClickHouse는 GitLab Duo 에이전트 채팅, 코드 제안, GitLab Duo 코드 검토 및 에이전트 플랫폼 플로우에는 필요하지 않습니다. GitLab Duo 사용 분석이 필요한 경우 [ClickHouse](../../integration/clickhouse.md)(`docker.io/clickhouse/clickhouse-server`)도 전송하고 구성해야 합니다.

FIPS 검증 환경의 경우 표준 이미지 대신 AI 게이트웨이 FIPS 이미지를 사용하세요. FIPS 이미지는 동일한 `self-hosted-vX.Y.Z-ee` 태그 형식을 사용합니다. FIPS 버전 태그는 GitLab 18.10 이상에서 사용 가능합니다. 자세한 내용은 [FIPS 검증 이미지](../../install/install_ai_gateway.md#fips-validated-images)를 참조하세요.

### LLM 모델 가중치 {#llm-model-weights}

LLM 모델 가중치는 vLLM이 파일 시스템에서 직접 읽는 대용량 파일입니다. 이러한 파일은 컨테이너 이미지로 배포되지 않습니다.

Mistral Small 24B(~48 GB)는 이 페이지의 예제에서 사용됩니다. 코드 제안 및 GitLab Duo 채팅을 모두 지원합니다. 다른 모델 옵션 및 GPU 요구사항은 [지원되는 모델 및 하드웨어 요구사항](supported_models_and_hardware_requirements.md)을 참조하세요.

## 컨테이너 이미지 전송 {#transfer-container-images}

연결된 머신에서 필요한 이미지를 아카이브로 저장한 다음 오프라인 쪽의 내부 레지스트리로 로드하세요.

### 연결된 머신에서 이미지 저장 {#save-images-on-the-connected-machine}

이미지를 저장하려면 인터넷에 연결된 머신에서 다음 명령을 사용하여 `skopeo`을(를) 실행하세요:

```shell
GITLAB_VERSION="18.10.0"
EXECUTOR_VERSION="v0.0.6"
VLLM_VERSION="v0.18.1"

skopeo copy \
  docker://registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:self-hosted-v${GITLAB_VERSION}-ee \
  docker-archive:aigw.tar

skopeo copy \
  docker://registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:${EXECUTOR_VERSION} \
  docker-archive:executor.tar

skopeo copy \
  docker://docker.io/vllm/vllm-openai:${VLLM_VERSION} \
  docker-archive:vllm.tar
```

연결된 머신이 프록시를 사용하는 경우 `skopeo`을(를) 실행하기 전에 `HTTPS_PROXY`을(를) 설정하세요:

```shell
export HTTPS_PROXY="http://proxy.example.com:8080"
```

또는 skopeo를 사용할 수 없는 경우 `docker save`을(를) 사용하세요:

```shell
GITLAB_VERSION="18.10.0"

docker pull registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:self-hosted-v${GITLAB_VERSION}-ee
docker save \
  registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:self-hosted-v${GITLAB_VERSION}-ee \
  --output aigw.tar
```

### 내부 레지스트리로 이미지 로드 {#load-images-into-the-internal-registry}

아카이브를 오프라인 환경으로 전송한 다음 내부 레지스트리로 로드하세요.

> [!note]
> 셸 변수는 머신 간에 지속되지 않습니다. 오프라인 호스트에서 `INTERNAL_REGISTRY`, `GITLAB_VERSION`, `EXECUTOR_VERSION` 및 `VLLM_VERSION`을(를) 다시 설정하세요.

내부 레지스트리가 자체 서명된 인증서를 사용하는 경우 skopeo를 신뢰하도록 구성하세요:

```shell
mkdir --parents /etc/containers/certs.d/<registry-host>
cp ca.crt /etc/containers/certs.d/<registry-host>/ca.crt
```

그런 다음 이미지를 로드하세요:

```shell
INTERNAL_REGISTRY="registry.internal.example.com/duo"
GITLAB_VERSION="18.10.0"
EXECUTOR_VERSION="v0.0.6"
VLLM_VERSION="v0.18.1"

skopeo copy \
  docker-archive:aigw.tar \
  docker://${INTERNAL_REGISTRY}/ai-gateway:self-hosted-v${GITLAB_VERSION}-ee

skopeo copy \
  docker-archive:executor.tar \
  docker://${INTERNAL_REGISTRY}/workflow-generic-image:${EXECUTOR_VERSION}

skopeo copy \
  docker-archive:vllm.tar \
  docker://${INTERNAL_REGISTRY}/vllm-openai:${VLLM_VERSION}
```

## LLM 모델 가중치 전송 {#transfer-llm-model-weights}

연결된 머신에서 모델 가중치를 다운로드하려면 Hugging Face CLI 또는 `git lfs`을(를) 사용하세요.

Hugging Face CLI 사용:

```shell
pip install huggingface_hub
huggingface-cli download mistralai/Mistral-Small-3.2-24B-Instruct-2506 \
  --local-dir ./mistral-small-3.2-24b
```

`huggingface-cli`이(가) `huggingface_hub` 버전에서 사용할 수 없는 경우 동일한 인수를 사용하여 `hf download`을(를) 사용하세요.

`git lfs` 사용(Python 필요 없음):

```shell
dnf install --assumeyes git-lfs  # On Debian/Ubuntu: apt-get install git-lfs
git lfs install
git clone https://huggingface.co/mistralai/Mistral-Small-3.2-24B-Instruct-2506
```

다운로드된 디렉터리를 오프라인 환경으로 전송하고 vLLM 컨테이너에 액세스할 수 있는 파일 시스템 경로(예: `/data/models/mistral-small-3.2-24b`)에 배치하세요.

## AI 게이트웨이 시작 {#start-the-ai-gateway}

내부 레지스트리 이미지로 AI 게이트웨이 컨테이너를 실행하려면:

1. 필요한 JWT 서명 키를 생성하세요:

   ```shell
   openssl genrsa -out aigw_signing.key 2048
   openssl genrsa -out aigw_validation.key 2048
   openssl genrsa -out duo_workflow_jwt.key 2048
   openssl genrsa -out duo_workflow_validation.key 2048
   ```

1. 내부 레지스트리 이미지를 사용하여 AI 게이트웨이 컨테이너를 실행하세요:

   ```shell
   INTERNAL_REGISTRY="registry.internal.example.com/duo"
   GITLAB_VERSION="18.10.0"
   GITLAB_DOMAIN="gitlab.internal.example.com"

   docker run --detach \
     --publish 5052:5052 \
     --publish 50052:50052 \
     --env AIGW_GITLAB_URL=https://${GITLAB_DOMAIN} \
     --env AIGW_GITLAB_API_URL=https://${GITLAB_DOMAIN}/api/v4/ \
     --env AIGW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat aigw_signing.key)" \
     --env AIGW_SELF_SIGNED_JWT__VALIDATION_KEY="$(cat aigw_validation.key)" \
     --env DUO_WORKFLOW_AUTH__ENABLED="true" \
     --env DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat duo_workflow_jwt.key)" \
     --env DUO_WORKFLOW_SELF_SIGNED_JWT__VALIDATION_KEY="$(cat duo_workflow_validation.key)" \
     --env DUO_WORKFLOW_AUTH__OIDC_CUSTOMER_PORTAL_URL= \
     ${INTERNAL_REGISTRY}/ai-gateway:self-hosted-v${GITLAB_VERSION}-ee
   ```

`DUO_WORKFLOW_AUTH__OIDC_CUSTOMER_PORTAL_URL=`을(를) 빈 문자열로 설정하면 AI 게이트웨이가 오프라인 환경에서 사용할 수 없는 CustomersDot 서비스에 도달하려는 시도를 방지합니다. 이 설정이 없으면 각 요청은 20초 지연이 발생합니다.

TLS 종료 및 추가 구성 옵션은 [GitLab AI 게이트웨이 설치](../../install/install_ai_gateway.md)를 참조하세요.

## vLLM 시작 {#start-vllm}

vLLM을 실행하여 전송된 모델 가중치를 제공하세요:

```shell
INTERNAL_REGISTRY="registry.internal.example.com/duo"
VLLM_VERSION="v0.18.1"

docker run --detach \
  --gpus all \
  --volume /data/models/mistral-small-3.2-24b:/model \
  --publish 8000:8000 \
  ${INTERNAL_REGISTRY}/vllm-openai:${VLLM_VERSION} \
  --model /model \
  --served_model_name custom_openai/mistral-small-3.2-24b \
  --tensor-parallel-size <number-of-gpus>
```

`<number-of-gpus>`을(를) 사용 가능한 GPU 수로 바꾸세요. 단일 GPU의 경우 `--tensor-parallel-size 1`을(를) 사용하세요. Podman의 경우 `--gpus all`을(를) `--device nvidia.com/gpu=all --security-opt label=disable`로 바꾸세요. `--security-opt label=disable` 플래그는 SELinux 적용 시스템에서 GPU 디바이스 액세스에 필요합니다.

시작 후 모델이 로드되었는지 확인하세요:

```shell
curl --silent "http://localhost:8000/v1/models"
```

- vLLM 구성에 대한 자세한 내용은 [지원되는 LLM 제공 플랫폼](supported_llm_serving_platforms.md)을 참조하세요.
- vLLM 배포 방법에 대한 자세한 내용은 [vLLM을 사용한 예제 모델 배포](vllm_gpt_oss_120b.md)를 참조하세요.

## GitLab에서 AI 게이트웨이 구성 {#configure-the-ai-gateway-in-gitlab}

AI 게이트웨이 및 vLLM이 실행 중인 후 GitLab을 구성하여 사용하세요:

1. 오른쪽 위 모서리에서 **운영자**를 선택하세요.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택하세요.
1. **구성 변경**을 선택하세요.
1. **로컬 AI 게이트웨이 URL** 아래에서 `http://<ai-gateway-host>:5052`을(를) 입력하세요.
1. **GitLab Duo Agent Platform 서비스의 로컬 URL** 아래에서 `<ai-gateway-host>:50052`을(를) 입력하세요.
1. **GitLab Duo 에이전트 플랫폼**을(를) 켜세요. 켠 후에는 **플로우 실행** 섹션이 확장됩니다.
1. **이미지 레지스트리** 아래에서 내부 레지스트리 URL(예: `registry.internal.example.com/duo`)을 입력하세요.
1. **변경 사항 저장**을 선택합니다.

## 자체 호스팅 모델 추가 {#add-the-self-hosted-model}

GitLab 인스턴스에 자체 호스팅 모델 배포를 추가하세요:

1. 오른쪽 위 모서리에서 **운영자**를 선택하세요.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택하세요.
1. **GitLab Duo 모델 구성**을 선택하세요.
1. **자체 호스팅 모델 추가**를 선택하세요.
1. 필드를 완성합니다:
   - **엔드포인트**의 경우 vLLM 서버의 URL을 입력하세요.
   - **모델 식별자**의 경우 `custom_openai/mistral-small-3.2-24b`을(를) 입력하세요.
1. 선택사항. **연결 테스트**를 선택하여 AI 게이트웨이가 vLLM 엔드포인트에 도달할 수 있는지 확인하세요.
1. **자체 호스팅 모델 추가**를 선택하세요.

## 오프라인 플로우 실행 구성 {#configure-offline-flow-execution}

오프라인 플로우 실행의 경우 `duo-cli`이(가) 사전 설치된 사용자 정의 실행기 이미지를 사용하세요.

1. 연결된 머신에서 사용자 정의 이미지를 빌드하세요:

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:v0.0.6
   RUN npm install --global @gitlab/duo-cli@8.86.0
   ```

   현재 `duo-cli` 버전을 찾으려면 GitLab Rails 소스의 `DUO_CLI_VERSION` 상수를 확인하거나 [GitLab Duo CLI npm 페이지](https://www.npmjs.com/package/@gitlab/duo-cli)를 참조하세요.

1. 위에서 설명한 동일한 `skopeo copy` 절차를 사용하여 이미지를 내부 레지스트리로 전송한 다음 프로젝트의 `agent-config.yml`에서 이를 참조하세요:

   ```yaml
   image: registry.internal.example.com/duo/duo-executor:v0.0.6
   ```

## 배포 확인 {#verify-the-deployment}

1. AI 게이트웨이가 실행 중인지 확인하세요:

   ```shell
   curl --silent "http://<ai-gateway-host>:5052/monitoring/healthz"
   ```

1. GitLab Duo 헬스 체크를 실행하세요:
   1. 오른쪽 위 모서리에서 **운영자**를 선택하세요.
   1. 왼쪽 사이드바에서 **GitLab Duo**를 선택하세요.
   1. **헬스 체크 실행**을 선택하세요.

   헬스 체크는 AI 게이트웨이 연결성 및 라이센스 상태를 검증합니다. 모델 추론을 테스트하지 않습니다.

1. 모델 추론을 확인하려면 GitLab UI 또는 IDE에서 GitLab Duo 채팅 또는 코드 제안을 통해 테스트 요청을 보내세요.

1. 에이전트 플랫폼 플로우를 확인하려면 플로우를 트리거하고 실행기 이미지가 내부 레지스트리에서 가져오고 `duo-cli`이(가) npm에서 다운로드되지 않는지 확인하세요.

일반적인 문제는 [문제 해결](troubleshooting.md)을 참조하세요.

## 아티팩트 업데이트 {#update-artifacts}

GitLab 인스턴스를 업그레이드할 때 동일한 절차를 사용하여 업데이트된 컨테이너 이미지를 전송하세요. 새 GitLab 버전과 일치하는 AI 게이트웨이 이미지 태그를 사용하세요.

GitLab을 업그레이드할 때 모델 가중치를 업데이트할 필요는 없습니다. 다른 모델로 변경할 때만 업데이트가 필요합니다.

## 관련 항목 {#related-topics}

- [오프라인 GitLab](../../topics/offline/_index.md)
- [자체 호스팅 모델](_index.md)
