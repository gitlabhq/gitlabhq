---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "vLLM을 사용하여 GPT OSS 120B 모델을 배포하는 예시로, GPU 선택부터 프로덕션 모니터링까지 다룹니다."
title: vLLM을 사용한 예시 모델 배포
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GPT OSS 120B는 vLLM으로 배포하기 위한 예시 모델로, GPU 선택부터 프로덕션 모니터링까지 다룹니다.

## GPU 선택 {#gpu-selection}

GPT OSS 120B는 NVIDIA H100에서 학습되었으며 H100 이상의 데이터 센터 GPU에서 최적으로 실행됩니다. 혼합 전문가(MoE) 아키텍처는 각 토큰에 대해 네트워크의 일부만 활성화하므로 모델이 단일 H100 80GB GPU에 맞습니다.

### 병렬 처리 전략 결정 {#determine-a-parallelism-strategy}

GPU가 연결되는 방식에 따라 다음 병렬 처리 전략이 결정됩니다:

- GPU가 NVLink(초당 수백 GB)를 통해 연결되면 단일 노드에서 텐서 병렬 처리를 사용하세요. 텐서 병렬 처리는 각 레이어를 GPU에 분산하며 높은 대역폭이 필요합니다.
- GPU가 낮은 대역폭을 가지고 PCIe(약 초당 64GB)로 작동하면 파이프라인 병렬 처리를 사용하세요. 파이프라인 병렬 처리는 레이어를 GPU에 순차적으로 분산합니다.

텐서 병렬 처리에서 최대 한계에 도달했지만 더 많은 모델 분산이 필요한 경우 두 병렬 처리 전략을 결합할 수 있습니다. 예를 들어, 노드 내에서는 텐서 병렬 처리를 사용하고 노드 간에는 파이프라인 병렬 처리를 사용합니다.

## VRAM 요구 사항 계획 {#plan-vram-requirements}

필요한 VRAM은 컨텍스트 길이와 예상 동시성에 따라 달라집니다.

vLLM은 다음 용도로 VRAM을 할당합니다:

| 범주 | 크기 | 참고 |
| --- | --- | --- |
| 모델 가중치 | 약 61GB | 고정 |
| 프레임워크 오버헤드 | 약 2GB | 고정 |
| KV 캐시 | 나머지 | 동시성 및 컨텍스트 길이에 따라 확장됨 |

KV 캐시는 각 요청에서 처리된 토큰의 사전 계산된 벡터 저장소입니다. 각 토큰은 한 번만 계산되며 모든 가변성이 존재하는 곳입니다.

### 예시: 단일 H100 80GB {#example-single-h100-80-gb}

`--gpu-memory-utilization 0.95`을 사용하면 76GB의 사용 가능한 VRAM을 얻습니다:

```plaintext
76 GB usable
├── 61 GB  model weights          ← fixed
├──  2 GB  framework overhead     ← fixed
└──  13 GB  KV cache               ← fills as requests arrive
```

캐시된 토큰당 약 36KB에서 13GB는 완전한 주의 레이어에서 약 370K 토큰의 컨텍스트를 보유합니다. 각 에이전트 요청이 약 32K 토큰을 사용하는 경우 약 _10개의 동시 요청_을 실행할 수 있습니다.

vLLM을 시작하면 로그가 정확한 숫자를 확인합니다:

```plaintext
Available KV cache memory: N GiB
GPU KV cache size: Y tokens
Maximum concurrency for Y tokens per request: Nx
```

## 설치 {#install}

환경과 일치하는 옵션을 선택하세요:

아래에 나열된 버전 번호는 GPT OSS 120B를 제공하는 데 필요한 최소 버전입니다. 최신 vLLM 릴리스 사용을 권장합니다. 성능 개선, 버그 수정 및 확장된 하드웨어 지원이 포함되어 있습니다.

- 설치 스크립트:  CUDA 또는 GPU 드라이버가 설치되지 않은 새로운 Ubuntu 또는 Debian 머신입니다.
- vLLM만:  CUDA 및 드라이버가 이미 설치되어 있습니다(GCP의 NVIDIA Deep Learning VM, AWS Deep Learning AMI 또는 기존 GPU 머신).
- Docker:  모든 호스트 수준 설정을 완전히 건너뜁니다.

다른 하드웨어가 있는 경우 추가 구성을 위해 [GPT OSS - vLLM Recipes](https://docs.vllm.ai/projects/recipes/en/latest/OpenAI/GPT-OSS.html#installation-vllm)를 참조하세요.

### 옵션 1:  설치 스크립트(처음부터) {#option-1-installation-script-from-scratch}

스택을 업데이트할 때 각 변수에 대해 다음 버전을 사용하세요:

| 변수 | 버전 |
|---|---|
| CUDA 툴킷 | 12.9 |
| 최소 드라이버 | 575.x |
| Python | 3.12 |
| vLLM | 0.18.0 |

```shell
#!/bin/bash
# vLLM + CUDA installation for gpt-oss-120b
# Target: Ubuntu 22.04 / Debian 12, x86_64

CUDA_VERSION="12-9"           # apt package suffix  →  cuda-toolkit-12-9
MIN_DRIVER_VERSION="575"      # minimum driver for CUDA 12.9
PYTHON_VERSION="3.12"
VLLM_VERSION="0.18.0"
VENV_DIR="${HOME}/vllm-env"

set -e

# ===========================================================================
# PART 1 — system prerequisites
# ===========================================================================
echo "--- Part 1: System prerequisites ---"

sudo apt-get update && sudo apt-get upgrade -y

sudo apt-get install -y \
    build-essential \
    dkms \
    linux-headers-$(uname -r) \
    wget curl gnupg2 \
    software-properties-common \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-venv \
    python${PYTHON_VERSION}-dev \
    python3-pip git

# Install uv — recommended by vLLM docs; gives extra index URLs higher
# priority than PyPI, which is required for the gpt-oss fork to resolve correctly.
curl --location --silent --show-error --fail "https://astral.sh/uv/install.sh" | sh
source "${HOME}/.local/bin/env"

# ===========================================================================
# PART 2 — NVIDIA drivers and CUDA toolkit
# Reboot required after this section before continuing to Part 3.
# ===========================================================================
echo "--- Part 2: NVIDIA drivers and CUDA ${CUDA_VERSION//-/.} ---"

# Add NVIDIA's package repository.
# For Debian 12, replace ubuntu2204 with debian12 in the URL.
# Current keyring URL: https://developer.nvidia.com/cuda-downloads
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update

# cuda-drivers (no version suffix) is a meta-package — apt resolves
# the latest driver compatible with the pinned toolkit automatically.
sudo apt-get install -y \
    cuda-drivers \
    cuda-toolkit-${CUDA_VERSION} \
    nvidia-gds-${CUDA_VERSION}

echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc

# Keep GPU initialised between jobs (reduces cold-start latency)
sudo systemctl enable nvidia-persistenced

echo "Rebooting to load NVIDIA kernel modules..."
echo "After reboot, run:  bash install.sh --post-reboot"

if [[ "${1:-}" != "--post-reboot" ]]; then
    sudo reboot
fi

# ===========================================================================
# PART 3 — Python environment and vLLM
# Start here after reboot, or if using a cloud managed image.
# ===========================================================================
echo "--- Part 3: Verify drivers ---"

nvidia-smi       # confirm driver >= ${MIN_DRIVER_VERSION} and GPUs visible
nvcc --version   # confirm CUDA ${CUDA_VERSION//-/.}

echo "--- Part 3: Python environment ---"

uv venv "$VENV_DIR" --python ${PYTHON_VERSION} --seed
source "$VENV_DIR/bin/activate"

python --version   # should show Python 3.12.x

echo "--- Part 3: PyTorch ---"

# --torch-backend=auto inspects your installed CUDA driver at runtime and
# selects the matching PyTorch index automatically. This replaces hardcoded
# --index-url flags and stays correct across CUDA version updates.
uv pip install torch torchvision torchaudio --torch-backend=auto

echo "--- Part 3: vLLM ---"

uv pip install "vllm==${VLLM_VERSION}" --torch-backend=auto


echo ""
echo "Installation complete."
echo "Activate environment:  source ${VENV_DIR}/bin/activate"
echo "Verify vLLM version:   python -c \"import vllm; print(vllm.__version__)\""
```

### 옵션 2: vLLM만 {#option-2-vllm-only}

CUDA 및 드라이버가 이미 설치되어 있을 때 vLLM을 설치하려면 다음 명령을 사용하세요(클라우드 관리형 이미지 및 기존 GPU 머신).

```shell
uv venv
source .venv/bin/activate
uv pip install vllm --torch-backend=auto
```

### 옵션 3:  Docker {#option-3-docker}

GPT OSS 120B Docker 이미지를 설치하려면 다음 명령을 사용하세요. `vllm/vllm-openai:v0.18.0` 이미지에는 CUDA, 드라이버 및 vLLM이 포함됩니다.

```shell
docker run \
  --gpus all \
  -p 8000:8000 \
  --ipc=host \
  vllm/vllm-openai:v0.18.0 \
  --model openai/gpt-oss-120b
```

## vLLM 구성 {#vllm-configuration}

vLLM 구성의 값은 트래픽 패턴에 따라 달라집니다. 아래의 규정된 설정으로 시작한 다음 이 레버를 조정하세요.

| 플래그 | 기본값 | 설명 |
|---|---|---|
| `--gpu-memory-utilization` | `0.90` | vLLM이 청구하는 GPU 메모리의 분수입니다. `0.95`로 증가시켜 KV 캐시를 확대하고 처리량을 개선하세요. 부하 상태에서 OOM 오류가 발생하면 감소시키세요. |
| `--max-model-len` | 모델 최대값(GPT OSS 120B의 경우 128K) | 요청당 최대 컨텍스트 길이를 제한합니다. 이 값을 낮추면 동시 용량이 증가합니다. |
| `--max-num-seqs` | `256` | 단일 배치의 최대 요청 수입니다. 더 높은 값은 요청당 지연 시간을 대가로 GPU 사용률 및 처리량을 개선합니다. 실제 동시성은 여전히 사용 가능한 KV 캐시로 제한됩니다. |
| `--max-num-batched-tokens` | 없음 | 반복당 처리되는 총 토큰입니다. `--max-num-seqs`과 함께 작동합니다. vLLM은 먼저 도달한 한계까지 배치합니다. |
| `--tensor-parallel-size` | 없음 | 레이어를 N개의 GPU에 걸쳐 수평으로 분산합니다. 높은 대역폭이 필요합니다. NVLink를 통해 연결된 단일 노드 내에서 사용하세요. |
| `--pipeline-parallel-size` | 없음 | 레이어를 N개의 GPU에 걸쳐 순차적으로 분산합니다. 낮은 대역폭을 허용합니다. PCIe를 통해 노드 간에 적합합니다. |

## 규정된 설정 {#prescriptive-setups}

다음 표는 각 하드웨어에 대한 규정된 설정을 나열합니다. 하드웨어 및 예상 트래픽 패턴과 일치하는 행을 선택한 다음 해당 구성을 사용하세요.

`Approximate concurrent requests` 열은 `--max-num-seqs` 값이 아닌 나열된 컨텍스트 길이에서 대략적인 KV 캐시 제한 동시성을 표시합니다.

| 하드웨어      | 최대 컨텍스트 | 대략적인 동시 요청 | 최적용도                             |
| ------------- | ----------- | -------------------- | ------------------------------------ |
| 단일 H100 80GB | 32K         | 10                   | 개발/테스트, 낮은 트래픽 서빙     |
| 2× H100 80GB | 64K         | 34                   | 중간 규모 프로덕션 부하               |
| 4× H100 80GB | 128K        | 51                   | 전체 컨텍스트 윈도우, 높은 처리량 |
| 2× A100 40GB | 32K         | 3                    | 최소 실행 가능한 A100 설정            |
| 4× A100 40GB | 32K         | 69                   | 더 높은 A100 처리량               |
| 2× L40S / RTX A6000 Ada 48GB | 32K | 19           | 예산 친화적인 Ada Lovelace 옵션  |

### 단일 H100 80GB {#single-h100-80-gb}

이 설정에서 높아진 `--gpu-memory-utilization`(0.95 vs. 기본값 0.90)은 [단일 H100의 알려진 CUDA OOM 문제](https://docs.vllm.ai/projects/recipes/en/latest/OpenAI/GPT-OSS.html#known-limitations)를 우회합니다.

```shell
vllm serve openai/gpt-oss-120b \
  --gpu-memory-utilization 0.95 \
  --max-model-len 32768 \
  --max-num-seqs 16 \
  --max-num-batched-tokens 4096
```

### 2× H100 80GB {#2-h100-80-gb}

이 설정에서 더 큰 결합 KV 캐시 풀은 더 높은 컨텍스트 윈도우 및 더 많은 동시 요청을 지원합니다.

```shell
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 2 \
  --max-model-len 65536 \
  --max-num-seqs 32 \
  --max-num-batched-tokens 8192
```

### 4× H100 80GB {#4-h100-80-gb}

이 설정은 완전한 128K 컨텍스트 윈도우를 제공합니다.

```shell
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 4 \
  --gpu-memory-utilization 0.95 \
  --max-model-len 131072 \
  --max-num-seqs 64 \
  --max-num-batched-tokens 16384
```

### 2× A100 40GB {#2-a100-40-gb}

이 설정에서 단일 A100 40GB는 61GB 모델 가중치를 보유할 수 없습니다. 최소 2개의 GPU가 필요합니다.

```shell
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 2 \
  --max-model-len 32768 \
  --max-num-seqs 24 \
  --max-num-batched-tokens 4096
```

### 4× A100 40GB {#4-a100-40-gb}

```shell
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 4 \
  --max-model-len 32768 \
  --max-num-seqs 128 \
  --max-num-batched-tokens 16384
```

### 2× L40S 48GB 또는 RTX A6000 Ada 48GB {#2-l40s-48gb-or-rtx-a6000-ada-48-gb}

두 설정 모두 48GB의 Ada Lovelace를 사용합니다.

```shell
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 2 \
  --max-model-len 32768 \
  --max-num-seqs 16 \
  --max-num-batched-tokens 4096
```

추가 NVIDIA Blackwell 및 Hopper 최적화를 위해 [GPT OSS - vLLM Recipes: NVIDIA Blackwell & Hopper 하드웨어](https://docs.vllm.ai/projects/recipes/en/latest/OpenAI/GPT-OSS.html#recipe-for-nvidia-blackwell-hopper-hardware)에 대한 레시피를 참조하세요.

## 서버 확인 {#verify-the-server}

vLLM을 시작한 후 다음 요청으로 올바르게 제공되는지 확인하세요:

```shell
curl "http://localhost:8000/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openai/gpt-oss-120b",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 64
  }'
```

모델의 완료와 함께 JSON 응답이 표시됩니다. 서버가 아직 준비되지 않은 경우 연결 거부 오류가 발생합니다. vLLM은 첫 시작 시 모델 가중치를 로드하는 데 시간이 필요하며 스토리지 속도에 따라 몇 분이 걸릴 수 있습니다.

## 모니터링 {#monitoring}

vLLM은 Prometheus 호환 `/metrics` 엔드포인트를 노출합니다. 전체 목록은 [프로덕션 메트릭 - vLLM](https://docs.vllm.ai/en/stable/usage/metrics/)을 참조하세요.

vLLM을 모니터링하려면 사용자 대면 지연 시간 및 용량 압력에 대한 메트릭을 확인하세요.

| 메트릭 | 설명 |
|---|---|
| **User-facing latency** | |
| `time_to_first_token` | 사용자가 응답성으로 느끼는 것입니다. |
| `time_per_output_token_seconds` | 스트리밍이 얼마나 부드러운지입니다. |
| **Capacity pressure** | |
| `kv_cache_usage_perc` | 사용 중인 KV 풀의 분수입니다. 주요 메모리 압력 신호입니다. 0.85 이상의 지속된 값은 용량에 접근하고 있음을 나타냅니다. |
| `num_requests_waiting` | KV 캐시가 가득 차서 대기열에 있는 요청입니다. 지속적으로 증가하는 대기열은 용량을 초과했음을 의미합니다. GPU를 확장하고 `--max-model-len`을 줄이거나 `--max-num-seqs`을 낮추세요. |
| `num_requests_running` | 실제 동시성입니다. |

## 문제 해결 {#troubleshooting}

### 클라이언트가 시간 초과되거나 `num_requests_waiting`이 계속 증가함 {#clients-are-timing-out-or-num_requests_waiting-keeps-growing}

들어오는 요청이 KV 캐시 용량을 초과합니다. vLLM은 캐시 공간이 해제될 때까지 새로운 요청을 대기열에 넣으며 대기열이 절대 비워지지 않습니다.

이 문제를 해결하려면:

1. `kv_cache_usage_perc`을 확인하세요. 0.85 이상의 지속된 값은 메모리 제약을 확인합니다.
1. 요청당 KV 할당을 낮추려면 `--max-model-len`을 줄이세요. 이렇게 하면 더 많은 동시 요청을 위한 슬롯이 해제됩니다.
1. 캐시를 위해 동시에 경쟁하는 요청 수를 제한하려면 `--max-num-seqs`을 줄이세요.
1. 단일 노드 튜닝을 완료한 경우 수평으로 확장하세요: GPU 또는 노드를 추가하고 여러 vLLM 인스턴스 간에 부하를 분산합니다.

### 서버가 CUDA OOM 오류로 충돌함 {#server-crashes-with-cuda-oom-errors}

서버가 높은 부하에서 GPU 메모리를 모두 사용합니다.

이 문제를 해결하려면 다음 순서로 이 조정을 수행하세요:

1. 동시 배치 크기를 제한하려면 `--max-num-seqs`을 줄이세요.
1. 요청당 KV 할당을 축소하려면 `--max-model-len`을 줄이세요.
1. OOM이 시작 시 발생하는 경우 `--gpu-memory-utilization`을 낮추세요.

### 토큰 생성이 예상보다 느림 {#token-generation-is-slower-than-expected}

`time_per_output_token_seconds`이 높고 전체 토큰/초가 낮습니다. GPU는 반복당 충분한 작업을 처리하지 않습니다.

이 문제를 해결하려면:

1. vLLM이 반복당 더 많은 토큰을 처리하도록 하려면 `--max-num-batched-tokens`을 증가시키세요.
1. 더 많은 요청이 함께 배치되도록 `--max-num-seqs`을 증가시키세요. 이렇게 하면 GPU 사용률이 향상됩니다.
